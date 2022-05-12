require "./spec_helper"

describe MM::ParameterSet do
  describe "#[]=" do
    it "appends an improper" do
      improper = MM::ImproperType.new(force_constant: 1.1, eq_value: 180)

      params = MM::ParameterSet.new
      params[{"A", "B", "C", "D"}] = improper
      params.impropers[{"A", "B", "C", "D"}]?.should eq improper
      params.impropers[{"A", "B", "D", "C"}]?.should eq improper
      params.impropers[{"C", "B", "A", "D"}]?.should eq improper
      params.impropers[{"C", "B", "D", "A"}]?.should eq improper
      params.impropers[{"D", "B", "A", "C"}]?.should eq improper
      params.impropers[{"D", "B", "C", "A"}]?.should eq improper
    end
  end
end
