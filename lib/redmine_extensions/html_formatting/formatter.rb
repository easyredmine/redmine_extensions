module RedmineExtensions
  module HTMLFormatting
    class Formatter < String
      include ActionView::Helpers::TagHelper

      RULES = [:tidy_html_from_editor, :rinku_auto_link, :inline_auto_link, :inline_auto_mailto]

      def to_html(*rules, &block)
        ret = self.dup
        RULES.each do |rule_name|
          ret = (method(rule_name).call(ret) || ret)
        end
        ret
      end

      private

      AUTO_LINK_RE = %r{
	                      (                          # leading text
	                        #<\w+.*?>|               # leading HTML tag, or
	                        [^=<>!:'"/]|             # leading punctuation, or
	                        \{\{\w+\(|               # inside a macro?
	                        ^                        # beginning of line
	                      )
	                      (
	                        (?:https?://)|           # protocol spec, or
	                        (?:s?ftps?://)|
	                        (?:www\.)|               # www.*
                          (?:smb://)|
                          (?:file://)
	                      )
	                      (
	                        (\S+?)                   # url
	                        (\/)?                    # slash
	                      )
	                      ((?:&gt;)?|[^\w\=\/;\(\)]*?)               # post
	                      (?=<|\s|&nbsp;|$)
	    }x unless const_defined?(:AUTO_LINK_RE)

      def rinku_auto_link(text)
        Rinku.auto_link(text) if defined?(Rinku)
      end

      # Turns all urls into clickable links (code from Rails).
      def inline_auto_link(text, regex_rules = AUTO_LINK_RE)
        text.gsub!(regex_rules) do
          all, leading, proto, url, post = $&, $1, $2, $3, $6

          if leading =~ /<a\s/i || leading =~ /![<>=]?/ || leading =~ /\{\{\w+\(/
             #don't replace URL's that are already linked
             #and URL's prefixed with ! !> !< != (textile images)
            all
          else
             #Idea below : an URL with unbalanced parethesis and
             #ending by ')' is put into external parenthesis
            if ( url[-1]==?) and ((url.count("(") - url.count(")")) < 0 ) )
              url=url[0..-2] # discard closing parenth from url
              post = ")"+post # add closing parenth to post
            end

            tag = content_tag('a', proto + url, :href => "#{proto == 'www.' ? "http://#{proto}" : proto}#{url}", :class => 'external', :target => '_blank')
            %(#{leading}#{tag}#{post})
          end
        end
      end

      # Turns all email addresses into clickable links (code from Rails).
      def inline_auto_mailto(text)
        text.gsub!(/([\w\.!#\$%\-+.]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+)/) do
          mail = $1
          if text.match(/<a\b[^>]*>(.*)(#{Regexp.escape(mail)})(.*)<\/a>/)
            mail
          else
            content_tag('a', mail, :href => "mailto:#{mail}", :class => "email")
          end
        end
      end

      # Tidy html. Fix html tags for correct show pages.
      def tidy_html_from_editor(text)
        Nokogiri::HTML::DocumentFragment.parse(text).to_html
      end

    end
  end
end
