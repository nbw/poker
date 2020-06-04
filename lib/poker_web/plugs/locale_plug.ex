defmodule PokerWeb.Plugs.Locale do
  import Plug.Conn

  @locales Gettext.known_locales(PokerWeb.Gettext)

  def init(_opts), do: nil

  # Set the locale
  def call(%Plug.Conn{params: %{"locale" => locale}} = conn, _opts) when locale in @locales do
    Gettext.put_locale(PokerWeb.Gettext, locale)

    put_session(conn, :locale, locale)
  end

  # Maintain locale
  def call(conn, _opts) do
    case get_session(conn, :locale) do
      nil -> conn
        put_session(conn, :locale, Gettext.get_locale())
      locale ->
        put_session(conn, :locale, locale)
    end
  end
end
