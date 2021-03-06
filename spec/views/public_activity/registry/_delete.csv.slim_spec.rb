# frozen_string_literal: true

require "rails_helper"

describe "public_activity/webhook/_delete.csv.slim" do
  let!(:registry)       { create(:registry) }
  let!(:user)           { create(:admin) }
  let!(:team)           { create(:team, owners: [user]) }
  let!(:namespace)      { create(:namespace, team: team, registry: registry) }
  let(:repository_name) { "busybox" }
  let(:tag_name)        { "latest" }
  let(:manifest)        { OpenStruct.new(id: "id", digest: "digest") }

  before do
    user.create_personal_namespace!
  end

  it "renders the activity properly" do
    allow_any_instance_of(::Portus::RegistryClient).to receive(:manifest).and_return(manifest)
    allow_any_instance_of(::Portus::RegistryClient).to receive(:delete).and_return(true)

    # Adding a repo like this so it also creates a tag and activities beneath it
    # all.
    event = { "actor" => { "name" => user.username } }
    Repository.add_repo(event, namespace, repository_name, tag_name)
    ::Namespaces::DestroyService.new(user).execute(namespace)

    activity = PublicActivity::Activity.find_by(key: "registry.delete")
    text = render "public_activity/registry/delete.csv.slim", activity: activity
    expect(text).to include "user,-,removed namespace,#{namespace.clean_name},#{user.username}"
  end
end
