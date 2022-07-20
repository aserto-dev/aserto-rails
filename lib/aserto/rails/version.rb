# frozen_string_literal: true

module Aserto
  module Rails
    VERSION = File.read(
      File.join(__dir__, "..", "..", "..", "VERSION")
    ).chomp
  end
end
