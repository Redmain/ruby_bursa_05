class PaginationForReports
  class LinkRenderer < WillPaginate::ActionView::LinkRenderer

    def link(text, target, attributes = {})
      attributes["data-remote"] = @options[:link_remote]
      attributes["data-type"] = @options[:link_type]
      attributes["data-result-type"] = @options[:link_result_type]
      (@options[:data] || []).inject({}) do |res, (i, v)|
        attributes["data-#{i}"] = v
      end
      super
    end

    protected
      def page_number(page)
        unless page == current_page
          tag(:li, link(page, page, rel: rel_value(page)))
        else
          tag(:li, page, class: "current")
        end
      end

      def previous_or_next_page(page, text, classes)
        link(text, page, { class: classes[:link] } ) if page
      end

      def html_container(html)
        html =  [
                  tag(:span, 'Страница'),
                  tag(:span, "#{current_page} из #{@total_pages}"),
                  tag(:span, html)
                ].join.html_safe
        tag(:div, html, container_attributes.merge({ class: 'pagination-block' }))
      end

      def previous_page
        num = @collection.current_page > 1 && @collection.current_page - 1
        previous_or_next_page(num, tag(:i, nil, class: "icon-prev"), { link: 'btn-prev' })
      end

      def next_page
        num = @collection.current_page < total_pages && @collection.current_page + 1
        previous_or_next_page(num, tag(:i, nil, class: "icon-next"), { link: 'btn-next' })
      end

      def gap
        text = @template.will_paginate_translate(:page_gap) { '&hellip;' }
        %(<li>#{text}</li>)
      end
  end
end

# <div class="pagination-block">
#   <span>Строк на странице</span>
#   <span>
#     <select class="default-select">
#       <option>10</option>
#       <option>5</option>
#     </select>
#   </span>
#   <span>10 из 300</span>
# </div>