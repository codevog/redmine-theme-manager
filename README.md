# Themes manager plugin

* Compatible with Redmine 2.6.x or higher

## Install

* Cd to your redmine plugins/ directory
* Git-clone the plugin from this repository into a folder: theme_manager (You must name your directory with underscores as shown here, or the plugin will throw a fatal error)
* Then you can install all the gems required by plugin using the following command:
    <pre><code>
    bundle install --without development test
    </code></pre>
* Run plugin migrations using the following command:
    <pre><code>
    bundle exec rake redmine:plugins:migrate RAILS_ENV=production
    </code></pre>
* Restart your Redmine web servers

## Usage
* Sign in as Admin user
* Go to 'Administration' section -> 'Theme manager'

 ![plugins list](/screenshots/scr-1.jpg)

* There you have a list of the themes uploaded.

 ![themes list](/screenshots/scr-3.jpg)

* You can upload a new theme from your local computer as zip archive or from git repository.

 ![upload theme](/screenshots/scr-2.jpg)
