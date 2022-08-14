defmodule Bertil.Messages do
  def reply_text_message(msg, channel_id),
    do: encode_msg(%{id: 1_234_141, type: "message", text: msg, channel: channel_id})

  def reply_not_registered(channel_id),
    do:
      encode_msg(%{id: 1_234_141, type: "message", text: "Register first!", channel: channel_id})

  def encode_msg(msg), do: {:text, Jason.encode!(msg)}
end