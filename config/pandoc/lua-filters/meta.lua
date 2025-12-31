function Meta(meta)
	-- Get the home path
	home = os.getenv("HOME")

	meta.lang = "en"
	meta.favicon = "favicon.ico"

	-- Dynamic date
	meta.date = os.date("%a %d %b %Y")

	-- Author example
	if not meta.author then
		meta.author = os.getenv("USER")
	end

	-- Custom variable for templates
	meta.version = "v1.0.0"

	-- Website or project link
	meta.project_url = "https://github.com/pritam"

	-- Keywords (table)
	meta.keywords = { "Markdown", "Pandoc", "Lua", "Automation" }

	return meta
end
