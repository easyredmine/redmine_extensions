class EasyProjectQuery < EasyQuery

  def entity
    Project
  end

  attributes_options :id, :easy_baseline_for_id, reject: true

end
