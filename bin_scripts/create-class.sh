#!/bin/sh

# Template for header file (.hpp)
HPP=$(
	cat <<'EOF'
#pragma once

#include <iostream>
#include <string>

class ClassName {
 private:
	int id;
	std::string name;

 public:
	ClassName();
	ClassName(int id, const std::string& name);
	~ClassName();

	int getId() const;
	std::string getName() const;

	void setId(int id);
	void setName(const std::string& name);

	void displayInfo() const;
};
EOF
)

# Template for source file (.cpp)
CPP=$(
	cat <<'EOF'
#include "CLASSNAME.hpp"

ClassName::ClassName() : id(0), name("Unnamed") {
	;
}

ClassName::ClassName(int id, const std::string& name) : id(id), name(name) {
	;
}

ClassName::~ClassName() {
	;
}

int ClassName::getId() const {
	return id;
}
std::string ClassName::getName() const {
	return name;
}

void ClassName::setId(int id) {
	this->id = id;
}

void ClassName::setName(const std::string& name) {
	this->name = name;
}

void ClassName::displayInfo() const {
	std::cout << "ID: " << id << ", Name: " << name << std::endl;
}
EOF
)

# --- Ask user for destination folder first ---
if ! FOLDER=$(zenity --file-selection \
	--directory --filename="$PWD/src" \
	--title="Select a folder in your project"); then
	exit 1
fi

# --- Loop until a unique class name is provided ---
while true; do
	class_name=$(zenity --entry \
		--title="Create C++ Class" \
		--text="Enter the class name (e.g., Student Manager)" \
		--entry-text="Foo") || {
		exit 1
	}

	# Remove spaces
	clean_name=$(echo "$class_name" | tr -d ' ')

	# Convert to PascalCase (first letter of each word uppercase)
	pascal_name=$(echo "$clean_name" | awk '{
	    for(i=1;i<=NF;i++){
	        $i=toupper(substr($i,1,1)) substr($i,2)
	    }
	    gsub(" ","")
	    print
	}')

	# Convert to camelCase for file name
	first_char=$(echo "$pascal_name" | cut -c1 | tr '[:upper:]' '[:lower:]')
	rest_chars=$(echo "$pascal_name" | cut -c2-)
	camel_name="${first_char}${rest_chars}"

	HEADER_FILE="${camel_name}.hpp"
	SOURCE_FILE="${camel_name}.cpp"

	header_path="$FOLDER/$HEADER_FILE"
	source_path="$FOLDER/$SOURCE_FILE"

	# Check if either file already exists
	if [ -e "$header_path" ] || [ -e "$source_path" ]; then
		zenity --warning --text="Files for class '$pascal_name' already exist in:\n$FOLDER\n\nPlease enter a different class name."
	else
		break
	fi
done

# --- Replace placeholders and generate files ---
HPP_FINAL=$(echo "$HPP" | sed "s/ClassName/$pascal_name/g" | sed "s/CLASSNAME/$camel_name/g")
CPP_FINAL=$(echo "$CPP" | sed "s/ClassName/$pascal_name/g" | sed "s/CLASSNAME/$camel_name/g")

# --- Write files ---
echo "$HPP_FINAL" >"$header_path"
echo "$CPP_FINAL" >"$source_path"
