
api = 2

core = 7.x

; Modules
; --------
projects[humanitarianresponse_documents][type] = "module"
projects[humanitarianresponse_documents][download][type] = "git"
projects[humanitarianresponse_documents][download][url] = "gitosis@viguierjust.com:humanitarianresponse/humanitarianresponse_documents.git"
projects[humanitarianresponse_documents][download][branch] = "master"

projects[humanitarianresponse_users][type] = "module"
projects[humanitarianresponse_users][download][type] = "git"
projects[humanitarianresponse_users][download][url] = "gitosis@viguierjust.com:humanitarianresponse/humanitarianresponse_users.git"
projects[humanitarianresponse_users][download][branch] = "master"

projects[humanitarianresponse_layout][type] = "module"
projects[humanitarianresponse_layout][download][type] = "git"
projects[humanitarianresponse_layout][download][url] = "gitosis@viguierjust.com:humanitarianresponse/humanitarianresponse_layout.git"
projects[humanitarianresponse_layout][download][branch] = "master"

; Themes
; ------
projects[humanitarianresponse][type] = "theme"
projects[humanitarianresponse][download][type] = "git"
projects[humanitarianresponse][download][url] = "gitosis@viguierjust.com:humanitarianresponse/theme.git"
projects[humanitarianresponse][download][branch] = "master"

; Libraries
; ---------
libraries[profiler][download][type] = "get"
libraries[profiler][download][url] = "http://ftp.drupal.org/files/projects/profiler-7.x-2.0-beta1.tar.gz"

libraries[grupal][download][type] = "git"
libraries[grupal][download][url] = "gitosis@viguierjust.com:grupal/profiler.git"
libraries[grupal][download][branch] = "master"
