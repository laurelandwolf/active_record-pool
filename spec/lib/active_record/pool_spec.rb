require "spec_helper"

RSpec.describe ActiveRecord::Pool do
  with_model :Activity do
    table do |schema|
      schema.string :kind
      schema.string :category
    end
  end
  let(:model) { Activity }

  before do
    allow(Thread).to receive(:new).and_yield.and_return(instance_double("Thread", join: true))
    75.times do
      Activity.create(kind: "like")
    end
    25.times do
      Activity.create(kind: "dislike")
    end
  end

  describe ".pool" do
    context 'with an delete' do
      let(:pool) do
        model.pool(columns: [:id, :kind]) do |id, kind|
          if kind == "like" then delete(id) end
        end
      end

      it "deletes 75 likes" do
        expect { pool }.to change(Activity.where(kind: "like"), :count).from(75).to(0)
      end
    end

    context 'with an insert' do
      let(:pool) do
        model.pool(columns: [:id, :kind]) do |id, kind|
          if kind == "like" then insert(kind: "response", category: "like") end
        end
      end

      it "creates 75 responses likes" do
        expect { pool }.to change(Activity.where(kind: "response", category: "like"), :count).from(0).to(75)
      end
    end

    context 'with an update' do
      let(:pool) do
        model.pool(columns: [:id, :kind]) do |id, kind|
          if kind == "like" then update(id, kind: "dislike") end
        end
      end

      it "updates 75 likes to dislikes" do
        expect { pool }.to change(Activity.where(kind: "dislike"), :count).from(25).to(100)
      end
    end
  end
end
