package com.flexsol.videoeditor

import android.graphics.BitmapFactory
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.RecyclerView
import com.flexsol.videoeditor.utils.ProjectManager
import com.flexsol.videoeditor.utils.SavedProject

class SavedProjectsAdapter(
    private var projects: List<SavedProject> = emptyList(),
    private val onProjectClick: (SavedProject) -> Unit,
    private val onOptionsClick: (View, SavedProject) -> Unit
) : RecyclerView.Adapter<SavedProjectsAdapter.ProjectViewHolder>() {

    fun updateProjects(newProjects: List<SavedProject>) {
        val diffResult = DiffUtil.calculateDiff(object : DiffUtil.Callback() {
            override fun getOldListSize(): Int = projects.size
            override fun getNewListSize(): Int = newProjects.size

            override fun areItemsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
                return projects[oldItemPosition].id == newProjects[newItemPosition].id
            }

            override fun areContentsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
                val old = projects[oldItemPosition]
                val new = newProjects[newItemPosition]
                return old.name == new.name &&
                        old.lastModifiedAt == new.lastModifiedAt &&
                        old.durationMs == new.durationMs &&
                        old.clipCount == new.clipCount
            }
        })
        this.projects = newProjects
        diffResult.dispatchUpdatesTo(this)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ProjectViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_saved_project, parent, false)
        return ProjectViewHolder(view)
    }

    override fun onBindViewHolder(holder: ProjectViewHolder, position: Int) {
        val project = projects[position]
        holder.bind(project)
    }

    override fun getItemCount(): Int = projects.size

    inner class ProjectViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val ivThumbnail: ImageView = itemView.findViewById(R.id.ivProjectThumbnail)
        private val ivFallbackIcon: ImageView = itemView.findViewById(R.id.ivProjectFallbackIcon)
        private val tvDuration: TextView = itemView.findViewById(R.id.tvProjectDuration)
        private val tvName: TextView = itemView.findViewById(R.id.tvProjectName)
        private val tvSource: TextView = itemView.findViewById(R.id.tvProjectSource)
        private val tvDate: TextView = itemView.findViewById(R.id.tvProjectDate)
        private val tvClips: TextView = itemView.findViewById(R.id.tvProjectClips)
        private val btnOptions: ImageView = itemView.findViewById(R.id.btnProjectOptions)

        fun bind(project: SavedProject) {
            tvName.text = project.name
            tvSource.text = project.sourceName
            tvDuration.text = ProjectManager.formatDuration(project.durationMs)
            tvDate.text = ProjectManager.formatDate(project.lastModifiedAt)
            tvClips.text = "${project.clipCount} ${if (project.clipCount == 1) "clip" else "clips"}"

            // Thumbnail loading
            if (project.thumbnailFile != null && project.thumbnailFile.exists()) {
                try {
                    val bitmap = BitmapFactory.decodeFile(project.thumbnailFile.absolutePath)
                    if (bitmap != null) {
                        ivThumbnail.setImageBitmap(bitmap)
                        ivThumbnail.visibility = View.VISIBLE
                        ivFallbackIcon.visibility = View.GONE
                    } else {
                        ivThumbnail.setImageDrawable(null)
                        ivFallbackIcon.visibility = View.VISIBLE
                    }
                } catch (e: Exception) {
                    ivThumbnail.setImageDrawable(null)
                    ivFallbackIcon.visibility = View.VISIBLE
                }
            } else {
                ivThumbnail.setImageDrawable(null)
                ivFallbackIcon.visibility = View.VISIBLE
            }

            itemView.setOnClickListener {
                onProjectClick(project)
            }

            btnOptions.setOnClickListener { v ->
                onOptionsClick(v, project)
            }
        }
    }
}

