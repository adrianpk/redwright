namespace :specifications do
  desc "Export legacy database document bodies to project files without changing the database"
  task export_legacy: :environment do
    connection = ActiveRecord::Base.connection
    abort "This database has no legacy document bodies." unless connection.column_exists?(:documents, :body)
    Project.find_each do |project|
      rows = connection.select_all("SELECT * FROM documents WHERE project_id = #{connection.quote(project.id)}").to_a
      next if rows.empty?
      ids = rows.map { |row| row.fetch("id").to_i }.join(",")
      edges = connection.select_all("SELECT * FROM document_relations WHERE from_artifact_id IN (#{ids})").to_a
      entries = Specifications::LegacyExporter.new(project: project, documents: rows, relations: edges).export!
      puts "Exported #{entries.size} document files for project #{project.id}."
    end
  end

  desc "Rebuild the derived project document index from files"
  task reindex: :environment do
    Project.find_each do |project|
      next unless ProjectProtocols::FileStore.for_project(project).root.directory?
      Document.reconcile!(project)
      puts "Indexed project #{project.id}."
    end
  end
end

namespace :specifications do
  desc "Prepare a separate database from original migrations while preserving existing domain data"
  task :prepare_database, [:output] => :environment do |_, arguments|
    abort "Provide a new output database path." if arguments[:output].blank?
    result = Specifications::DatabaseRebuild.prepare!(output_path: arguments[:output])
    puts "Prepared #{result.fetch(:database)}. The original database is unchanged."
    puts "Source snapshot: #{result.fetch(:source_snapshot)}"
  end
end
