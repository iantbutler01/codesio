defmodule CodesioWeb.SnippetController do
  use CodesioWeb, :controller
  alias Codesio.SnippetsDisplay
  alias Codesio.SnippetsDisplay.Snippet
  alias CodesioHelpers.ElasticsearchHelper
  def index(conn, _params) do
    snippets = SnippetsDisplay.list_snippets()
    render(conn, "index.html", layout: {CodesioWeb.LayoutView, "snippet_index.html"}, snippets: snippets)
  end

  def new(conn, _params) do
    changeset = SnippetsDisplay.change_snippet(%Snippet{})
    render(conn, "new.html", changeset: changeset, languages: CodesioWeb.get_supported_languages())
  end

  def create(conn, %{"snippet" => %{ "tags" => tags } = snippet_params}) do
    tags = cond do
      is_list(tags) -> tags
      is_binary(tags) -> String.split(tags, ",", trim: true)
      true -> nil
    end
    case SnippetsDisplay.create_snippet(%{ snippet_params | "tags" => tags }) do
      {:ok, snippet} ->
        params = %{ snippet_params | "tags" => tags }
        params = Map.put(params, "id", snippet.id)
        ElasticsearchHelper.insert_into(params)
        conn
        |> put_flash(:info, "Snippet added successfully.")
        |> redirect(to: snippet_path(conn, :show, snippet))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, languages: CodesioWeb.get_supported_languages())
    end
  end

  def show(conn, %{"id" => id}) do
    snippet = SnippetsDisplay.get_snippet!(id)
    render(conn, "show.html", snippet: snippet)
  end

  def edit(conn, %{"id" => id}) do
    snippet = SnippetsDisplay.get_snippet!(id)
    changeset = SnippetsDisplay.change_snippet(snippet)
    render(conn, "edit.html", snippet: snippet, changeset: changeset, languages: CodesioWeb.get_supported_languages())
  end
  defp persist_changes(snippet, snippet_params, conn) do
    case SnippetsDisplay.update_snippet(snippet, snippet_params) do
      {:ok, snippet} ->
        conn
        |> put_flash(:info, "Snippet updated successfully.")
        |> redirect(to: snippet_path(conn, :show, snippet))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", snippet: snippet, changeset: changeset, languages: CodesioWeb.get_supported_languages())
    end
  end
  def update(conn, %{"id" => id, "snippet" => %{ "tags" => tags } = snippet_params}) when is_list(tags) do
    snippet = SnippetsDisplay.get_snippet!(id)
    persist_changes(snippet, snippet_params, conn)
  end
  def update(conn, %{"id" => id, "snippet" => %{ "tags" => tags } = snippet_params}) when is_binary(tags) do
    snippet = SnippetsDisplay.get_snippet!(id)
    tags = String.split(tags, ",", trim: true)
    persist_changes(snippet, %{snippet_params | "tags" => tags}, conn)
  end

  def delete(conn, %{"id" => id}) do
    snippet = SnippetsDisplay.get_snippet!(id)
    {:ok, _snippet} = SnippetsDisplay.delete_snippet(snippet)

    conn
    |> put_flash(:info, "Snippet deleted successfully.")
    |> redirect(to: snippet_path(conn, :index))
  end
end
