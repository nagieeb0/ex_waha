defimpl ExWaha.Session.Keyable, for: ExWahaNative.Account do
  def key(%{session: session}), do: {:native, session}
end
