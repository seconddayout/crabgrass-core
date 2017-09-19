##
## Here in lies all the helpers for displaying icons, avatars, spinners,
## and various images.
##

module Common::Ui::ImageHelper
  IMAGE_SIZES = Hash.new(200).merge(small: 64,
                                    medium: 200,
                                    large: 500).freeze

  ##
  ## ICON
  ##

  #
  # for example: icon_tag('pencil')
  #
  # currently, any 'size' argument other than the default will not display well.
  #
  def icon_tag(icon, size: 16, title: '')
    content_tag :i, ' ', class: "small_icon #{icon}_#{size}", title: title
  end

  ##
  ## PAGES
  ##
  ## every page has an icon.
  ##

  ## returns the img tag for the page's icon
  def page_icon(page)
    content_tag :i, ' ', class: "page_icon #{page.icon}_16"
  end

  ##
  ## SPINNER
  ##
  ## spinners are animated gifs that are used to show progress.
  ## see JavascriptHelper for showing and hiding spinners.
  ##

  #
  # returns a spinner tag.
  # If this is in a ujs remote form it will automagically start and stop
  # spinning as the form is submitted.
  #
  # arguments:
  #
  #  id -- unique name of the spinner
  #  options -- hash of optional options
  #
  # options:
  #
  #  :show -- if true, default the spinner to be visible
  #  :align -- override the default vertical alignment. generally, should use the default except in <TD> elements with middle vertical alignment.
  #  :class -- add css classes to the spinner
  #  :spinner -- used a different image for the spinner
  #
  def spinner(id = nil, options = {})
    display = ('display:none;' unless options.delete(:show))
    align = "vertical-align:#{options[:align] || 'middle'}"
    options.reverse_merge! spinner: 'spinner.gif',
                           style: "#{display} #{align};",
                           class: 'spin',
                           id: id && spinner_id(id),
                           alt: ''
    options[:src] = "/images/#{options.delete(:spinner)}"
    tag :img, options
  end

  def text_spinner(text, id, options = {})
    span_options = {
      id: spinner_id(id),
      style: ('display:none;' unless options.delete(:show)),
      class: 'spin'
    }
    content_tag :span, span_options do
      options[:style] = 'vertical-align:baseline'
      spinner(nil, options) + text
    end
  end

  def spinner_id(id)
    if id.is_a? ActiveRecord::Base
      id = dom_id(id, 'spinner')
    else
      "#{id}_spinner"
    end
  end

  def spinner_icon_on(icon, id)
    target = id ? "$('#{id}')" : 'eventTarget(event)'
    "replaceClassName(#{target}, '#{icon}_16', 'spinner_icon')"
  end

  def spinner_icon_off(icon, id)
    target = id ? "$('#{id}')" : 'eventTarget(event)'
    "replaceClassName(#{target}, 'spinner_icon', '#{icon}_16')"
  end

  def big_spinner
    content_tag :div, '', style: 'background: white url(/images/spinner-big.gif) no-repeat 50% 50%; height: 5em;', class: 'spin'
  end

  # we can almost do this to trick ie into working with event.target,
  # which would eliminate the need for random ids.
  #
  # but it doesn't quite work, because for :complete of ajax, window.event
  # is not right
  #
  #  function eventTarget(event) {
  #    event = event || window.event; // IE doesn't pass event as argument.
  #    return(event.target || event.srcElement); // IE doesn't use .target
  #  }
  #
  # however, this can be used for non-ajax js.

  ##
  ## ASSET THUMBNAILS
  ##

  #
  # creates an img tag for a thumbnail, optionally scaling the image or cropping
  # the image to meet new dimensions (using html/css, not actually scaling/cropping)
  #
  # eg: thumbnail_img_tag(asset, :medium, :crop => '22x22')
  #
  # thumbnail_name: one of :small, :medium, :large
  #
  # options:
  #  * :crop   -- the img is first scaled, then cropped to allow it to
  #               optimally fit in the cropped space.
  #  * :scale  -- the img is scaled, preserving proportions
  #  * :crop!  -- crop, even if there is no known height and width
  #
  # note: if called directly, thumbnail_img_tag does not actually do the
  #       cropping. rather, it generate a correct img tag for use with
  #       link_to_asset.
  #
  def thumbnail_img_tag(asset, thumbnail_name, options = {}, html_options = {})
    display = ThumbnailDisplay.new(asset, thumbnail_name, options)
    image_tag display.url, html_options.merge(display.thumbnail_img_options)
  end

  class ThumbnailDisplay
    def initialize(asset, thumbnail_name, options = {})
      @asset = asset
      @thumbnail = asset.thumbnail(thumbnail_name)
      @options = options
      @options[:crop] ||= @options[:crop!]
    end

    #TODO: take crop! into account
    def thumbnail_img_options
      return { style: fallback_style } unless thumbnail
      if thumbnail.width && thumbnail.height
        style_options.merge size: size
      else
        {}
      end
    end

    def style_options
      if target_width > thumbnail.width || target_height > thumbnail.height
        { style: "margin: #{margin_y}px #{margin_x}px;" }
      else
        {}
      end
    end

    def size
      height = (thumbnail.height * ratio).round
      width  = (thumbnail.width * ratio).round
      return "#{width}x#{height}"
    end

    def fallback_style
      width, height = (options[:crop!] || '').split(/x/).map(&:to_f)
      if width.nil? or height.nil?
        'vertical-align: middle;'
      else
        "margin: #{(height - 22) / 2}px #{(width - 22) / 2}px;"
      end
    end

    def ratio
      # never scale up
      [1, fit_ratio].min
    end

    def url
      if thumbnail.present?
        thumbnail.url
      else
        "/images/png/16/#{asset.small_icon}.png"
      end
    end

    protected

    attr_reader :asset, :thumbnail, :options

    def fit_ratio
      if options[:crop]
        ratios.max
      else
        ratios.min
      end
    end

    def ratios
      [target_width / thumbnail.width, target_height / thumbnail.height]
    end

    def margin_x
      ((target_width - thumbnail.width) / 2) - border_width
    end

    def margin_y
      ((target_height - thumbnail.height) / 2) - border_width
    end

    def target_width
      target_size.split(/x/).map(&:to_f).first || thumbnail.width
    end

    def target_height
      target_size.split(/x/).map(&:to_f).second || thumbnail.height
    end

    def target_size
      (options[:crop] || options[:scale] || '')
    end

    def border_width
      1
    end
  end

  # links to an asset with a thumbnail preview
  def link_to_asset(asset, thumbnail_name, options = {})
    thumbnail = asset.thumbnail(thumbnail_name)
    img = thumbnail_img_tag(asset, thumbnail_name, options)
    if size = (options[:crop] || options[:scale] || options[:crop!])
      target_width, target_height = size.split(/x/).map(&:to_f)
    elsif thumbnail and thumbnail.width and thumbnail.height
      target_width = thumbnail.width
      target_height = thumbnail.height
    else
      target_width = 32
      target_height = 32
    end
    options[:class] ||= 'thumbnail'
    options[:title] ||= asset.filename
    options[:style]   = "height:#{target_height}px;width:#{target_width}px"
    url = options[:url] || asset.url
    link_to img, url, options.slice(:class, :title, :style, :method, :remote)
  end

  def icon_for(asset)
    image_tag "/images/png/16/#{asset.big_icon}.png", style: 'vertical-align: middle'
  end

  ##
  ## AGNOSTIC MEDIA
  ##

  def display_media(media, size = :medium)
    if media.respond_to?(:is_image?) and media.is_image?
      if media.respond_to?(:thumbnail)
        thumbnail = media.thumbnail(size)
        if thumbnail.nil? or thumbnail.failure?
          dims = case size
                 when :small  then '64x64'
                 when :medium then '200x200'
                 when :large  then '500x500'
                 end
          image_tag('/images/ui/corrupted/corrupted.png', size: dims)
        else
          image_tag(thumbnail.url, height: thumbnail.height, width: thumbnail.width)
        end
      else
        # not sure what we are trying to display
      end
    elsif media.respond_to?(:is_video?) and media.is_video?
      media.build_embed
    end
  end

  ##
  ## PICTURES
  ##

  #
  # Displays a Picture object as the background image of an empty div.
  #
  # 'size' can be either a Symbol :small, :medium, :large, or a Hash
  # of the format used by Picture geometry (see picture.rb)
  #
  def picture_tag(picture, size = :medium)
    content_tag :div, '', style: picture_style(picture, size)
  end

  def picture_style(picture, size = :medium)
    if size.is_a? Symbol
      pixels = IMAGE_SIZES[size]
      geometry = { max_width: pixels, min_width: pixels, max_height: pixels * 2 }
    else
      geometry = size
    end
    geometry = picture.add_geometry(geometry)
    width, height = picture.size(geometry)
    format('width: 100%%; max-width: %spx; height: %spx; background: url(%s)', width, height, picture.url(geometry))
  end
end
