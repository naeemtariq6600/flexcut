package com.flexsol.videoeditor.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.util.Log
import androidx.core.content.FileProvider
import com.flexsol.videoeditor.models.EditOperation
import com.flexsol.videoeditor.models.EditRecipe
import com.flexsol.videoeditor.models.VideoProject
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class SavedProject(
    val id: String,
    val file: File,
    var name: String,
    val sourceName: String,
    val sourceUri: Uri,
    val thumbnailFile: File?,
    val createdAt: Long,
    val lastModifiedAt: Long,
    val durationMs: Long,
    val clipCount: Int,
    val operationsCount: Int
)

object ProjectManager {

    private const val TAG = "ProjectManager"
    private const val PROJECTS_DIR_NAME = "projects"

    fun getProjectsDir(context: Context): File {
        val dir = File(context.filesDir, PROJECTS_DIR_NAME)
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }

    /**
     * Loads all saved projects from the internal projects directory, sorted by last modified descending.
     */
    fun loadSavedProjects(context: Context): List<SavedProject> {
        val dir = getProjectsDir(context)
        val files = dir.listFiles { f -> f.isFile && f.name.endsWith(".lcprj") } ?: return emptyList()
        
        val projects = mutableListOf<SavedProject>()
        for (file in files) {
            try {
                val id = file.nameWithoutExtension
                val json = file.readText()
                val recipe = ProjectSerializer.deserialize(json.reader())

                val thumbFile = File(dir, "$id.thumb.jpg").let { if (it.exists()) it else null }

                val duration = computeRecipeDuration(context, recipe)
                val mergeClips = recipe.operations.filterIsInstance<EditOperation.Merge>().flatMap { it.items }.size
                val clipCount = 1 + mergeClips

                projects.add(
                    SavedProject(
                        id = id,
                        file = file,
                        name = if (recipe.projectName.isNotBlank()) recipe.projectName else recipe.sourceName,
                        sourceName = recipe.sourceName,
                        sourceUri = recipe.sourceUri,
                        thumbnailFile = thumbFile,
                        createdAt = recipe.createdAt,
                        lastModifiedAt = file.lastModified().takeIf { it > 0 } ?: recipe.lastModifiedAt,
                        durationMs = duration,
                        clipCount = clipCount,
                        operationsCount = recipe.operations.size
                    )
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load project from ${file.name}", e)
            }
        }

        return projects.sortedByDescending { it.lastModifiedAt }
    }

    /**
     * Saves a video project into the internal projects directory.
     * Returns the saved project metadata.
     */
    fun saveProject(
        context: Context,
        project: VideoProject,
        customName: String? = null,
        existingProjectId: String? = null,
        thumbnailBitmap: Bitmap? = null
    ): SavedProject? {
        return try {
            val dir = getProjectsDir(context)
            val id = existingProjectId ?: "proj_${System.currentTimeMillis()}"
            val projFile = File(dir, "$id.lcprj")

            val existingName = if (projFile.exists()) {
                try {
                    val r = ProjectSerializer.deserialize(projFile.readText())
                    r.projectName.takeIf { it.isNotBlank() }
                } catch (e: Exception) {
                    null
                }
            } else null

            val projectName = customName ?: existingName ?: (if (project.sourceName.isNotBlank()) project.sourceName else "My Project")

            val recipe = EditRecipe.fromVideoProject(projectName, project).copy(
                lastModifiedAt = System.currentTimeMillis()
            )
            val json = ProjectSerializer.serialize(recipe)

            projFile.writeText(json)

            // Save thumbnail if provided, or extract from source
            val thumbFile = File(dir, "$id.thumb.jpg")
            if (thumbnailBitmap != null) {
                try {
                    FileOutputStream(thumbFile).use { out ->
                        thumbnailBitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to write thumbnail", e)
                }
            } else if (!thumbFile.exists()) {
                // Try extracting from source
                try {
                    val r = MediaMetadataRetriever()
                    r.setDataSource(context, project.sourceUri)
                    val frame = r.getScaledFrameAtTime(0L, MediaMetadataRetriever.OPTION_CLOSEST_SYNC, 320, 240)
                    r.release()
                    if (frame != null) {
                        FileOutputStream(thumbFile).use { out ->
                            frame.compress(Bitmap.CompressFormat.JPEG, 85, out)
                        }
                    }
                } catch (e: Exception) {
                    Log.d(TAG, "Could not extract initial thumbnail: ${e.message}")
                }
            }

            val duration = computeRecipeDuration(context, recipe)
            val mergeClips = recipe.operations.filterIsInstance<EditOperation.Merge>().flatMap { it.items }.size
            val clipCount = 1 + mergeClips

            SavedProject(
                id = id,
                file = projFile,
                name = projectName,
                sourceName = project.sourceName,
                sourceUri = project.sourceUri,
                thumbnailFile = if (thumbFile.exists()) thumbFile else null,
                createdAt = recipe.createdAt,
                lastModifiedAt = projFile.lastModified(),
                durationMs = duration,
                clipCount = clipCount,
                operationsCount = project.operations.size
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save project", e)
            null
        }
    }

    /**
     * Deletes a project and its associated thumbnail.
     */
    fun deleteProject(context: Context, project: SavedProject): Boolean {
        return try {
            val dir = getProjectsDir(context)
            val thumbFile = File(dir, "${project.id}.thumb.jpg")
            if (thumbFile.exists()) thumbFile.delete()
            project.file.delete()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete project ${project.id}", e)
            false
        }
    }

    /**
     * Renames a project.
     */
    fun renameProject(context: Context, project: SavedProject, newName: String): Boolean {
        return try {
            val json = project.file.readText()
            val recipe = ProjectSerializer.deserialize(json.reader())
            val updatedRecipe = recipe.copy(
                projectName = newName,
                lastModifiedAt = System.currentTimeMillis()
            )
            val updatedJson = ProjectSerializer.serialize(updatedRecipe)
            project.file.writeText(updatedJson)
            project.name = newName
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to rename project ${project.id}", e)
            false
        }
    }

    /**
     * Duplicates a project.
     */
    fun duplicateProject(context: Context, project: SavedProject): SavedProject? {
        return try {
            val dir = getProjectsDir(context)
            val newId = "proj_${System.currentTimeMillis()}"
            val json = project.file.readText()
            val recipe = ProjectSerializer.deserialize(json.reader())
            val newName = "${project.name} (Copy)"
            val duplicatedRecipe = recipe.copy(
                projectName = newName,
                createdAt = System.currentTimeMillis(),
                lastModifiedAt = System.currentTimeMillis()
            )
            val newFile = File(dir, "$newId.lcprj")
            newFile.writeText(ProjectSerializer.serialize(duplicatedRecipe))

            // Copy thumbnail if available
            val newThumbFile = File(dir, "$newId.thumb.jpg")
            if (project.thumbnailFile != null && project.thumbnailFile.exists()) {
                project.thumbnailFile.copyTo(newThumbFile, overwrite = true)
            }

            SavedProject(
                id = newId,
                file = newFile,
                name = newName,
                sourceName = duplicatedRecipe.sourceName,
                sourceUri = duplicatedRecipe.sourceUri,
                thumbnailFile = if (newThumbFile.exists()) newThumbFile else null,
                createdAt = duplicatedRecipe.createdAt,
                lastModifiedAt = newFile.lastModified(),
                durationMs = project.durationMs,
                clipCount = project.clipCount,
                operationsCount = project.operationsCount
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to duplicate project ${project.id}", e)
            null
        }
    }

    /**
     * Imports an external .lcprj file URI and stores it in the internal projects directory.
     */
    fun importExternalProject(context: Context, externalUri: Uri): SavedProject? {
        return try {
            val dir = getProjectsDir(context)
            val id = "proj_${System.currentTimeMillis()}"

            val recipe = context.contentResolver.openInputStream(externalUri)?.use { stream ->
                stream.bufferedReader().use { reader ->
                    ProjectSerializer.deserialize(reader)
                }
            } ?: return null

            val projFile = File(dir, "$id.lcprj")
            projFile.writeText(ProjectSerializer.serialize(recipe))

            val thumbFile = File(dir, "$id.thumb.jpg")
            try {
                val r = MediaMetadataRetriever()
                r.setDataSource(context, recipe.sourceUri)
                val frame = r.getScaledFrameAtTime(0L, MediaMetadataRetriever.OPTION_CLOSEST_SYNC, 320, 240)
                r.release()
                if (frame != null) {
                    FileOutputStream(thumbFile).use { out ->
                        frame.compress(Bitmap.CompressFormat.JPEG, 85, out)
                    }
                }
            } catch (e: Exception) {}

            val duration = computeRecipeDuration(context, recipe)
            val mergeClips = recipe.operations.filterIsInstance<EditOperation.Merge>().flatMap { it.items }.size

            SavedProject(
                id = id,
                file = projFile,
                name = if (recipe.projectName.isNotBlank()) recipe.projectName else recipe.sourceName,
                sourceName = recipe.sourceName,
                sourceUri = recipe.sourceUri,
                thumbnailFile = if (thumbFile.exists()) thumbFile else null,
                createdAt = recipe.createdAt,
                lastModifiedAt = projFile.lastModified(),
                durationMs = duration,
                clipCount = 1 + mergeClips,
                operationsCount = recipe.operations.size
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to import external project", e)
            null
        }
    }

    /**
     * Computes the effective duration of an EditRecipe in milliseconds.
     */
    fun computeRecipeDuration(context: Context, recipe: EditRecipe): Long {
        val trims = recipe.operations.filterIsInstance<EditOperation.Trim>()
        val speedOp = recipe.operations.filterIsInstance<EditOperation.SpeedMain>().lastOrNull()
        val speed = speedOp?.speed ?: 1.0f

        var mainDuration = 0L
        if (trims.isNotEmpty()) {
            val lastTrim = trims.last()
            mainDuration = ((lastTrim.endMs - lastTrim.startMs) / speed).toLong()
        } else {
            try {
                val r = MediaMetadataRetriever()
                r.setDataSource(context, recipe.sourceUri)
                val dur = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: 0L
                r.release()
                mainDuration = (dur / speed).toLong()
            } catch (e: Exception) {}
        }

        val mergeOps = recipe.operations.filterIsInstance<EditOperation.Merge>()
        val mergeDuration = mergeOps.flatMap { it.items }.sumOf { it.trimmedDurationMs }

        return (mainDuration + mergeDuration).coerceAtLeast(0L)
    }

    fun formatDuration(durationMs: Long): String {
        val totalSeconds = (durationMs / 1000L).coerceAtLeast(0)
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        val hours = minutes / 60
        return if (hours > 0) {
            String.format(Locale.getDefault(), "%d:%02d:%02d", hours, minutes % 60, seconds)
        } else {
            String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds)
        }
    }

    fun formatDate(timestamp: Long): String {
        val now = System.currentTimeMillis()
        val diff = now - timestamp
        val oneDay = 24 * 60 * 60 * 1000L

        return when {
            diff < 60 * 1000L -> "Just now"
            diff < 60 * 60 * 1000L -> "${diff / (60 * 1000L)}m ago"
            diff < oneDay && isSameDay(now, timestamp) -> {
                val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
                "Today, " + timeFormat.format(Date(timestamp))
            }
            diff < 2 * oneDay && isSameDay(now - oneDay, timestamp) -> {
                val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
                "Yesterday, " + timeFormat.format(Date(timestamp))
            }
            else -> {
                val dateFormat = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
                dateFormat.format(Date(timestamp))
            }
        }
    }

    private fun isSameDay(time1: Long, time2: Long): Boolean {
        val fmt = SimpleDateFormat("yyyyMMdd", Locale.getDefault())
        return fmt.format(Date(time1)) == fmt.format(Date(time2))
    }

    fun getProjectUri(context: Context, project: SavedProject): Uri {
        return try {
            FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", project.file)
        } catch (e: Exception) {
            Uri.fromFile(project.file)
        }
    }
}
