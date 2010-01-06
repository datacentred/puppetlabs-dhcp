# Puts a file snippet into a directory previously setup using fragment::concat
#
# OPTIONS:
#   - directory         The directory to put the files in
#                       This is also used by fragment::concat to find its 
#                       fragments. 
#   - content           If present puts the content into the file
#   - source            If content was not specified, use the source
#   - order             By default all files gets a 10_ prefix in the directory
#                       you can set it to anything else using this to influence 
#                       the order of the content in the file
#   - mode              Mode for the file
#   - owner             Owner of the file
#   - group             Owner of the file
define fragment(
  $directory, $content='', $source='', $order=10,
  $mode = 0644, $owner = root, $group = root
  ) {
  # if content is passed, use that, else if source is passed use that
  case $content {
    '':      {
      case $source {
        '':      { crit('No content or source specified')  }
        default: { File{ source => $source } }
      }
    }
    default: { File{ content => $content } }
  }
        
  file{"${directory}/snippets/${order}_${name}":
    mode    => $mode,
    owner   => $owner,
    group   => $group,
    ensure  => present,
    alias   => "concat_snippet_${name}",
    notify  => Exec["concat_${directory}"]
  }
}
