defmodule AshWahaTest do
  use ExUnit.Case, async: true

  test "DSL section exposes the expected schema keys" do
    section = AshWaha.Dsl.whatsapp_section()
    assert section.name == :whatsapp
    keys = Keyword.keys(section.schema)
    assert :account in keys
    assert :session_name in keys
    assert :on_event in keys
  end
end
