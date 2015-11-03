# Documentation Index Generator
## Description
The index generator creates a documentation tree of links in order to make a directory of documentation more available. It uses the following conventions;

- creates a header for each sub directory level, using the file name (made pretty) as the description
- creates a list item for each '.md' file, using the first line as the description
- ignores empty directories

## Usage
You can run the helper with:
```
markdownh generate_index <config_file>
```

Where <config_file> is a YAML file with the structure [below](#config-file)

The root of this repo contains an [erb template](../README.md.erb) and [config file](../.doc_index.yml) for an example.

## Config File
The config file used for this utility is a yaml file with the following key/value pairs:
- doc_directory: The relative path to your documentation from where you're running the command
- output_file: Where to write the file to
- erb_path: An erb file to use at the output_file template. To write the index, simply put `<%= @doc_tree %>` where you want it to go
- base_header: Since the documentation tree with indent based directories, you can specify what header level you want to start at. This is a string of '#'s
- ignore: A list of filenames to ignore. This uses `File.basename` (TODO: extend this to match path patterns)

Example
```yaml
doc_directory: './docs'
output_file: 'README.md'
erb_path: 'README.md.erb'
base_header: "###"
ignore:
  - 'images'
```

Example .erb template:
```
# Readme
This is a readme

The doc index will appear here:
<%= @doc_index %>
```
