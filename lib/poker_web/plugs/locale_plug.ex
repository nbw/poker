defmodule PokerWeb.Plugs.Locale do
  import Plug.Conn
  @moduledoc """
  Detects and sets locale

  Reference: https://phrase.com/blog/posts/set-and-manage-locale-data-in-your-phoenix-l10n-project/
  """

  @locales Gettext.known_locales(PokerWeb.Gettext)

  def init(_opts), do: nil

  # Set the locale
  def call(%Plug.Conn{params: %{"locale" => locale}} = conn, _opts) when locale in @locales do
    Gettext.put_locale(PokerWeb.Gettext, locale)

    conn
    |> put_resp_cookie("locale", locale, max_age: 10*24*60*60)
    |> put_session(:locale, locale)
  end

  # Maintain locale
  def call(conn, _opts) do
    locale = case get_session(conn, :locale) ||
      locale_from_cookies(conn) ||
        locale_from_header(conn) do
      nil -> Gettext.get_locale()
      loc -> loc
    end

    Gettext.put_locale(PokerWeb.Gettext, locale)

    put_session(conn, :locale, locale)
  end

  defp locale_from_cookies(conn) do
    conn.cookies["locale"]
  end

  defp locale_from_header(conn) do
    conn
    |> extract_accept_language
    |> Enum.find(nil, fn accepted_locale -> Enum.member?(@locales, accepted_locale) end)
  end

  def extract_accept_language(conn) do
    case Plug.Conn.get_req_header(conn, "accept-language") do
      [value | _] ->
        value
        |> String.split(",")
        |> Enum.map(&parse_language_option/1)
        |> Enum.sort(&(&1.quality > &2.quality))
        |> Enum.map(&(&1.tag))
        |> Enum.reject(&is_nil/1)
        |> ensure_language_fallbacks()
      _ ->
        []
    end
  end

  defp parse_language_option(string) do
    captures = Regex.named_captures(~r/^\s?(?<tag>[\w\-]+)(?:;q=(?<quality>[\d\.]+))?$/i, string)
    quality = case Float.parse(captures["quality"] || "1.0") do
      {val, _} -> val
      _ -> 1.0
    end
    %{tag: captures["tag"], quality: quality}
  end

  defp ensure_language_fallbacks(tags) do
    Enum.flat_map tags, fn tag ->
      [language | _] = String.split(tag, "-")
      if Enum.member?(tags, language), do: [tag], else: [tag, language]
    end
  end
end
