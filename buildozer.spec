[app]

# (str) Title of your application
title = Aptis

# (str) Package name
package.name = aptis

# (str) Package domain (needed for android packaging)
package.domain = org.aptis

# (list) Source files to include (let's include Python scripts and icons)
source.include_exts = py,png,jpg,kv,atlas

# (list) Source files to include (optional)
source.include_dir = 

# (list) List of directory to exclude from distribution
source.exclude_exts = spec

# (list) List of exclusions
source.exclude_dirs = tests, bin, .git, .github

# (str) Application versioning
version = 1.0.4

# (list) Application requirements
# Note: Including requests requires python3, kivy, and networking dependencies
requirements = python3,kivy,requests,urllib3,idna,charset_normalizer,certifi

# (str) Supported orientations (landscape, portrait or all)
orientation = landscape

# (str) Source directory where your main.py resides
source.dir = .

# (list) Permissions
android.permissions = INTERNET

# (int) Target Android API, should be as high as possible.
android.api = 33

# (int) Minimum API your APK will support.
android.minapi = 21

# (bool) Use AndroidX support
android.androidx = True

[buildozer]

# (int) Log level (0 = error, 1 = info, 2 = debug)
log_level = 2

# (int) Display warning if buildozer is run as root (0 = False, 1 = True)
warn_root = 1