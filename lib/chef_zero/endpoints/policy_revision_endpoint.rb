require_relative "../chef_data/data_normalizer"

module ChefZero
  module Endpoints
    # /organizations/ORG/policies/NAME/revisions/REVISION
    class PolicyRevisionEndpoint < RestBase
      # GET /organizations/ORG/policies/NAME/revisions/REVISION
      def get(request)
        data = parse_json(get_data(request))
        data[:policy_group_list] = Array.new

        # extracting policy name and revision
        request_policy_name = request.rest_path[3]
        request_policy_revision = request.rest_path[5]

        # updating the request to fetch the policy group list
        request.rest_path[2] = "policy_groups"
        request.rest_path = request.rest_path.slice(0,3)

        list_data(request).each do |group_name|
          group_path = request.rest_path + [group_name]

          # fetching all the policies associated with each group
          policy_list = list_data(request, group_path + ["policies"])
          policy_list.each do |policy_name|
            revision_id = parse_json(get_data(request, group_path + ["policies", policy_name]))

            # if the name and revision matchs, we add the group to the response
            if (policy_name == request_policy_name) && (revision_id == request_policy_revision)
              policy_group_list = data[:policy_group_list]
              data[:policy_group_list] = [group_name] + policy_group_list
            end
          end
        end
        
        data = ChefData::DataNormalizer.normalize_policy(data, request_policy_name, request_policy_revision)
        json_response(200, data)
      end

      # DELETE /organizations/ORG/policies/NAME/revisions/REVISION
      def delete(request)
        policyfile_data = parse_json(get_data(request))
        policyfile_data = ChefData::DataNormalizer.normalize_policy(policyfile_data, request.rest_path[3], request.rest_path[5])
        delete_data(request)
        json_response(200, policyfile_data)
      end
    end
  end
end
