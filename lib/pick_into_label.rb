class PickIntoLabel
  def self.for(version)
    %[~"Pick into #{version.to_minor}"]
  end
end
