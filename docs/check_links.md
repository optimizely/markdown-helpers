# Valid Link Checker
## Description
The link checker will check a pattern of files for valid external, internal (path), and markdown section ('#') links. It also has the ability to use the [oktokit](https://github.com/octokit/octokit.rb) for private github links.

## Usage
You can run the helper with:
```
markdownh check_links <config_file>
```

Where <config_file> is a YAML file with the structure [below](#config-file)

The root of this repo contains a [config file](../.check_links.yml) for an example.

## Config File
The config file has the following keys:
- include (required): A top level list for what different checks to run. The following sections can be modified for each item:
  - path (required): List of file paths to check (may be a ruby glob pattern)
  - pattern (required): Ruby regex to check each line against
  - exclude_comment: A string denoting to ignore checking a line
  - private_github: If true, it will check github.com links with the Oktokit API. This requires setting the GITHUB_OAUTH_TOKEN environment variable.
  - replacements: A list of `match: regex` to be replaced by `value: string`. This may be used to check links in an application running locally, or sub a URL for a local path.

Example:
```yaml
include:
  - paths:
      - './docs/*/**.md'
      - 'README.md'
    # get markdown links
    pattern: !ruby/regexp '/\[[^\]]*\]\(([^\)]*)\)/'
    # ignore links with <!--ignore--> in the line
    exclude_comment: '<!--ignore-->'
    # there are no private GitHub links in here
    private_github: false
    replacements:
      - match: /yourwebsite.com/
        value: localhost
```
