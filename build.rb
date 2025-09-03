#!/usr/bin/env ruby

require 'bundler'
require 'byebug'
require 'fileutils'
require 'pdfkit'
require 'kramdown'

require 'webrick'
include WEBrick

def parameterize(string, separator: "-", preserve_case: false, locale: nil, prefix: nil)
  # Replace accented chars with their ASCII equivalents.
  parameterized_string = string.dup.downcase

  parameterized_string = parameterized_string.gsub(/[^\w\s-]/, '').gsub("-", "").strip.gsub(/\s+/, '-')

  # Turn unwanted chars into the separator.
  parameterized_string.gsub!(/[^a-z0-9\-_]+/, separator)

  unless separator.nil? || separator.empty?
    if separator == "-"
      re_duplicate_separator        = /-{2,}/
      re_leading_trailing_separator = /^-|-$/
    else
      re_sep = Regexp.escape(separator)
      re_duplicate_separator        = /#{re_sep}{2,}/
      re_leading_trailing_separator = /^#{re_sep}|#{re_sep}$/
    end
    # No more than one of the separator in a row.
    parameterized_string.gsub!(re_duplicate_separator, separator)
    # Remove leading/trailing separator.
    parameterized_string.gsub!(re_leading_trailing_separator, "")
  end

  prefix.to_s + parameterized_string
end

def wrap_html(content, title = "Crisis Cadres")
  <<~HTML
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>#{title}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap"
      rel="stylesheet"
    />
    <style>
      #{File.read("pdf.css")}
    </style>
  </head>
  <body class="antialiased">
    <div class="prose">
      #{content}
    </div>
  </body>
  </html>
  HTML
end

chapters = File.read("toc.md").split("\n")
html_pages = []
toc_titles_as_links = []

chapters.each do |chapter|
 
  unless File.exist?("chapters/#{parameterize(chapter)}.md")
    puts "Missing chapter! chapters/#{parameterize(chapter)}.md"
    next
  end

  md_contents = File.read("chapters/#{parameterize(chapter)}.md")
  doc = Kramdown::Document.new(md_contents)
  html_output = doc.to_html

  File.write("output/html/#{parameterize(chapter)}.html", html_output)
  html_pages << html_output

  toc_titles_as_links << "<div><a href='##{parameterize(chapter)}'>#{chapter}</a></div>" unless chapter == "Crisis Cadres"
end

html_pages.insert(1, wrap_html("<div class='text-3xl mb-4'>Table of Contents</div>" + toc_titles_as_links.join))
joined_pages = html_pages.join("<div style='page-break-before: always'></div>")

port = 9091
server = HTTPServer.new(:Port => port,  :DocumentRoot => Dir.pwd)
trap("INT"){ server.shutdown }
Thread.new { server.start }

kit = PDFKit.new(wrap_html(joined_pages), 
                 page_width: '120',
                 page_height: '180' ,
                 margin_top: '0.5in',
                 margin_bottom: '0.5in',
                 margin_left: '0.5in',
                 margin_right: '0.5in',
                 print_media_type: false,
                 root_url: "http://localhost:#{port}/")

kit.to_file("output/pdf/crisis-cadres.pdf")
server.shutdown