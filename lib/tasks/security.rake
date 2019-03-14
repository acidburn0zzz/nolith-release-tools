namespace :security do
  desc 'Validate security merge requests'
  task :validate do
    ReleaseTools::Security::MergeRequestsValidator.new.execute
  end

  desc 'Merges valid security merge requests'
  task :merge, [:merge_master] do |_, args|
    merge_master =
      if args[:merge_master] && !args[:merge_master].empty?
        true
      else
        false
      end

    ReleaseTools::Security::MergeRequestsMerger
      .new(merge_master: merge_master)
      .execute
  end
end
