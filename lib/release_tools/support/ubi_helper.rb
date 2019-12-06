# frozen_string_literal: true

def ubi?(version)
  version.ee?
end

def ubi_tag(version, ubi_version = '8')
  version.tag(ee: true).gsub(/-ee$/, "-ubi#{ubi_version}")
end
