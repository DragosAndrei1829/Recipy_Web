module LegalHelper
  # Convert simple markdown-like text to HTML
  def render_legal_content(content)
    return "" if content.blank?

    lines = content.split("\n")
    html = []
    current_paragraph = []

    lines.each do |line|
      stripped = line.strip

      if stripped.start_with?("# ")
        # Flush current paragraph
        html << wrap_paragraph(current_paragraph) if current_paragraph.any?
        current_paragraph = []
        # Main heading
        html << content_tag(:h1, stripped[2..], class: "text-4xl font-extrabold text-gray-900 dark:text-white mb-4")
      elsif stripped.start_with?("## ")
        # Flush current paragraph
        html << wrap_paragraph(current_paragraph) if current_paragraph.any?
        current_paragraph = []
        # Section heading
        html << content_tag(:h2, stripped[3..], class: "text-2xl font-bold text-gray-900 dark:text-white mt-8 mb-3")
      elsif stripped.start_with?("### ")
        # Flush current paragraph
        html << wrap_paragraph(current_paragraph) if current_paragraph.any?
        current_paragraph = []
        # Subsection heading
        html << content_tag(:h3, stripped[4..], class: "text-xl font-semibold text-gray-900 dark:text-white mt-6 mb-2")
      elsif stripped.empty?
        # Empty line = end of paragraph
        html << wrap_paragraph(current_paragraph) if current_paragraph.any?
        current_paragraph = []
      else
        # Regular text
        current_paragraph << process_inline(stripped)
      end
    end

    # Don't forget last paragraph
    html << wrap_paragraph(current_paragraph) if current_paragraph.any?

    safe_join(html)
  end

  private

  def wrap_paragraph(lines)
    return "" if lines.empty?
    content_tag(:p, safe_join(lines, " "), class: "text-gray-700 dark:text-gray-200 leading-relaxed mb-4")
  end

  def process_inline(text)
    # Convert **bold** to <strong>
    text = text.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
    # Convert *italic* to <em>
    text = text.gsub(/\*(.+?)\*/, '<em>\1</em>')
    # Convert [link](url) to <a>
    text = text.gsub(/\[(.+?)\]\((.+?)\)/) do
      link_to($1, $2, class: "text-primary hover:underline font-semibold")
    end
    # Convert email addresses to links
    text = text.gsub(/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/) do
      link_to($1, "mailto:#{$1}", class: "text-primary hover:underline font-semibold")
    end

    text.html_safe
  end
end
