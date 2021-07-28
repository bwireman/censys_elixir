defmodule CensysEx.Hosts do
  @moduledoc """
  CensysEx wrapper for the search.censys.io v2 API for the "hosts" resource
  """
  alias CensysEx.{Paginate, Search, Util}

  @index "hosts"

  @doc """
  Hits the Censys Hosts search API. Returns a stream of results for your query

    - API docs: https://search.censys.io/api#/hosts/searchHosts
    - Syntax: https://search.censys.io/search/language?resource=hosts

  ## Examples

  ```
  CensysEx.Hosts.search("same_service(service_name: SSH and not port: 22)")
  |> Stream.take(25)
  |> Stream.map(&Map.get(&1, "ip"))
  |> Enum.to_list()
  ["10.0.0.6", "10.2.0.1", ...]
  ```
  """
  def search(query \\ "", per_page \\ 100),
    do: Search.search(@index, query, per_page)

  @doc """
  Hits the Censys Hosts view API. Returning full
  information about an IP at a given time

  - API docs: https://search.censys.io/api#/hosts/viewHost

  ## Examples

  ```
  CensysEx.Hosts.view("127.0.0.1")

  # View "127.0.0.1" at a certain time
  CensysEx.Hosts.view("127.0.0.1", ~U[2021-06-07 12:53:27.450073Z])
  ```
  """
  @spec view(String.t(), DateTime.t()) :: {:error, any()} | {:ok, map()}
  def view(ip, at_time \\ nil),
    do: Util.get_client().view(@index, ip, at_time)

  @doc """
  Hits the Censys Hosts view names API. Returning a stream of names for that IP.

  - API docs: https://search.censys.io/api#/hosts/viewHostNames

  ## Examples

  ```
  CensysEx.Hosts.names("127.0.0.1")
  ```
  """
  def names(ip) do
    next = fn params -> Util.get_client().get(@index, ip <> "/names", [], params) end
    extractor = fn client = %Paginate{} -> get_in(client.results, ["result", "names"]) end

    Paginate.stream(next, extractor)
  end

  @doc """
  Hits the Censys Hosts diff API.

  - API docs: https://search.censys.io/api#/hosts/viewHostDiff

  ## Examples

  ```
  # diff the current host with it self 🤷
  CensysEx.Hosts.diff("8.8.8.8")

  # diff two hosts
  CensysEx.Hosts.diff("8.8.8.8", "1.1.1.1")

  # diff a host with itself at a time in the past
  CensysEx.Hosts.diff("8.8.8.8", nil, ~U[2021-06-07 12:53:27.450073Z])

  # diff two hosts in the past
  CensysEx.Hosts.diff("8.8.8.8", "8.8.4.4" ~U[2021-06-07 12:53:27.450073Z], ~U[2021-06-07 12:53:27.450073Z])
  ```
  """
  @spec diff(String.t(), String.t(), DateTime.t(), DateTime.t()) :: {:error, any()} | {:ok, map()}
  def diff(ip, ip_b \\ nil, at_time \\ nil, at_time_b \\ nil),
    do: Util.get_client().get(@index, ip <> "/diff", [], params: Util.build_diff_params(ip_b, at_time, at_time_b))

  @doc """
  Hits the Censys Hosts aggregate API. Optionally control number of buckets returned

  - API docs: https://search.censys.io/api#/hosts/aggregateHosts

  ## Examples

  ```
  CensysEx.Hosts.aggregate("location.country_code", "services.service_name: MEMCACHED")

  CensysEx.Hosts.aggregate("location.country_code", "services.service_name: MEMCACHED", 1000)
  ```
  """
  @spec aggregate(String.t(), String.t(), integer()) :: {:error, any()} | {:ok, map()}
  def aggregate(field, query \\ nil, num_buckets \\ 50),
    do: Util.get_client().aggregate(@index, field, query, num_buckets)
end
