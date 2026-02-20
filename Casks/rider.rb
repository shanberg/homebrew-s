# frozen_string_literal: true

cask "rider" do
  version "0.1.0"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"

  url "https://github.com/shanberg/rider/releases/download/v#{version}/Rider-v#{version}.zip"
  name "Rider"
  desc "Window tasks overlay — todo overlay per window"
  homepage "https://github.com/shanberg/rider"

  app "Rider.app"
end
