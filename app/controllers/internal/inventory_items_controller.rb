module Internal
  class InventoryItemsController < ApplicationController
    def count
      result = InventoryApi.count_items(name: params[:name])
      status = result[:error] ? :bad_request : :ok

      render json: result, status:
    end
  end
end
