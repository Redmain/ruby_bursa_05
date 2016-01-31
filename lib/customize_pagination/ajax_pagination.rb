class AjaxPagination
  class LinkRenderer < WillPaginate::ActionView::LinkRenderer
    def pagination
      @options[:only_view_next]? [ :next_page ] : super
    end

    def link(text, target, attributes = {})
      attributes["data-remote"] = @options[:link_remote]
      attributes["class"] = @options[:link_class]
      attributes["data-type"] = @options[:link_type]
      attributes["data-result-type"] = @options[:link_result_type]
      super
    end

    def default_url_params
      @options[:link_params] || super
    end

    protected
      def page_number(page)
        unless page == current_page
          tag(:li, link(page, page, rel: rel_value(page)))
        else
          tag(:li, page, class: "current")
        end
      end

      def previous_or_next_page(page, text, classname)
        if page
          tag(:li, link(text, page), class: classname)
        else
          tag(:li, nil, class: classname)
        end
      end

      def html_container(html)
        tag(:ul, html, container_attributes)
      end

      def previous_page
        num = @collection.current_page > 1 && @collection.current_page - 1
        previous_or_next_page(num, @options[:previous_label], nil)
      end

      def next_page
        num = @collection.current_page < total_pages && @collection.current_page + 1
        previous_or_next_page(num, @options[:next_label], @options[:next_class])
      end

      def gap
        text = @template.will_paginate_translate(:page_gap) { '&hellip;' }
        %(<li>#{text}</li>)
      end
  end
end
