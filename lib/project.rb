module Project
  autoload :GitlabCe, 'project/gitlab_ce'
  autoload :GitlabEe, 'project/gitlab_ee'
  autoload :OmnibusGitlab, 'project/omnibus_gitlab'
  autoload :GitlabPages, 'project/gitlab_pages'
  autoload :GitlabCiYml, 'project/gitlab_ci_yml'
  autoload :SecurityProductsSast, 'project/security_products_sast'
  autoload :SecurityProductsCodequality, 'project/security_products_codequality'

  autoload :Release, 'project/release'
end
