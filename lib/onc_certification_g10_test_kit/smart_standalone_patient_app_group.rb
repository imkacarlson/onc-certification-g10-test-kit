require_relative 'base_token_refresh_group'
require_relative 'patient_context_test'
require_relative 'smart_scopes_test'
require_relative 'unauthorized_access_test'
require_relative 'unrestricted_resource_type_access_group'
require_relative 'well_known_capabilities_test'

module ONCCertificationG10TestKit
  class SmartStandalonePatientAppGroup < Inferno::TestGroup
    title 'Standalone Patient App - Full Access'
    short_title 'Standalone Patient App'

    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      Enter in the appropriate scope to enable patient-level access to all
      relevant resources. In addition, support for the OpenID Connect (openid
      fhirUser), refresh tokens (offline_access), and patient context
      (launch/patient) are required.
    )

    description %(
        This scenario demonstrates the ability of a system to perform a Patient
        Standalone Launch to a SMART on FHIR confidential client with a patient
        context, refresh token, OpenID Connect (OIDC) identity token, and use
        the GET HTTP method for code exchange. After launch, a simple Patient
        resource read is performed on the patient in context. The access token
        is then refreshed, and the Patient resource is read using the new access
        token to ensure that the refresh was successful. The authentication
        information provided by OpenID Connect is decoded and validated, and
        simple queries are performed to ensure that access is granted to all
        USCDI data elements.

        * [SMART on FHIR
          (STU1)](http://www.hl7.org/fhir/smart-app-launch/1.0.0/)
        * [SMART on FHIR
          (STU2)](http://hl7.org/fhir/smart-app-launch/STU2)
        * [OpenID Connect
          (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html)
      )
    id :g10_smart_standalone_patient_app
    run_as_group

    config(
      inputs: {
        client_secret: {
          optional: false,
          name: :standalone_client_secret
        }
      }
    )

    input_order :url, :standalone_client_id, :standalone_client_secret

    group from: :smart_discovery do
      required_suite_options(smart_app_launch_version: 'smart_app_launch_1')

      test from: 'g10_smart_well_known_capabilities',
           config: {
             options: {
               required_capabilities: [
                 'launch-standalone',
                 'client-public',
                 'client-confidential-symmetric',
                 'sso-openid-connect',
                 'context-standalone-patient',
                 'permission-offline',
                 'permission-patient'
               ]
             }
           }
    end

    group from: :smart_discovery_stu2 do
      required_suite_options(smart_app_launch_version: 'smart_app_launch_2')

      test from: 'g10_smart_well_known_capabilities',
           config: {
             options: {
               required_capabilities: [
                 'launch-standalone',
                 'client-public',
                 'client-confidential-symmetric',
                 'sso-openid-connect',
                 'context-standalone-patient',
                 'permission-offline',
                 'permission-patient',
                 'authorize-post',
                 'permission-v1',
                 'permission-v2'

               ]
             }
           }
    end

    group from: :smart_standalone_launch do
      required_suite_options(smart_app_launch_version: 'smart_app_launch_1')

      title 'Standalone Launch With Patient Scope'
      description %(
        # Background

        The [Standalone
        Launch Sequence](http://hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
        allows an app, like Inferno, to be launched independent of an
        existing EHR session. It is one of the two launch methods described in
        the SMART App Launch Framework alongside EHR Launch. The app will
        request authorization for the provided scope from the authorization
        endpoint, ultimately receiving an authorization token which can be used
        to gain access to resources on the FHIR server.

        # Test Methodology

        Inferno will redirect the user to the the authorization endpoint so that
        they may provide any required credentials and authorize the application.
        Upon successful authorization, Inferno will exchange the authorization
        code provided for an access token.

        For more information on the #{title}:

        * [Standalone Launch
          Sequence](http://hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
      )

      config(
        inputs: {
          requested_scopes: {
            default: %(
              launch/patient openid fhirUser offline_access
              patient/Medication.read patient/AllergyIntolerance.read
              patient/CarePlan.read patient/CareTeam.read patient/Condition.read
              patient/Device.read patient/DiagnosticReport.read
              patient/DocumentReference.read patient/Encounter.read
              patient/Goal.read patient/Immunization.read patient/Location.read
              patient/MedicationRequest.read patient/Observation.read
              patient/Organization.read patient/Patient.read
              patient/Practitioner.read patient/Procedure.read
              patient/Provenance.read patient/PractitionerRole.read
            ).gsub(/\s{2,}/, ' ').strip
          }
        }
      )

      test from: :g10_smart_scopes do
        config(
          inputs: {
            requested_scopes: { name: :standalone_requested_scopes },
            received_scopes: { name: :standalone_received_scopes }
          },
          options: {
            scope_version: :v1
          }
        )

        def required_scopes
          ['openid', 'fhirUser', 'launch/patient', 'offline_access']
        end

        def required_scope_type
          'patient'
        end
      end

      test from: :g10_unauthorized_access,
           config: {
             inputs: {
               patient_id: { name: :standalone_patient_id }
             }
           }

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :standalone_patient_id },
               smart_credentials: { name: :standalone_smart_credentials }
             }
           }
    end

    group from: :smart_standalone_launch_stu2,
          config: {
            inputs: {
              use_pkce: {
                default: 'true',
                locked: true
              },
              pkce_code_challenge_method: {
                locked: true
              },
              authorization_method: {
                name: :standalone_authorization_method,
                default: 'get',
                locked: true
              }
            }
          } do
      required_suite_options(smart_app_launch_version: 'smart_app_launch_2')

      title 'Standalone Launch With Patient Scope'
      description %(
        # Background

        The [Standalone
        Launch Sequence](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
        allows an app, like Inferno, to be launched independent of an
        existing EHR session. It is one of the two launch methods described in
        the SMART App Launch Framework alongside EHR Launch. The app will
        request authorization for the provided scope from the authorization
        endpoint, ultimately receiving an authorization token which can be used
        to gain access to resources on the FHIR server.

        # Test Methodology

        Inferno will redirect the user to the the authorization endpoint so that
        they may provide any required credentials and authorize the application.
        Upon successful authorization, Inferno will exchange the authorization
        code provided for an access token.

        For more information on the #{title}:

        * [Standalone Launch
          Sequence](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
      )

      config(
        inputs: {
          requested_scopes: {
            default: %(
              launch/patient openid fhirUser offline_access
              patient/Medication.rs patient/AllergyIntolerance.rs
              patient/CarePlan.rs patient/CareTeam.rs patient/Condition.rs
              patient/Device.rs patient/DiagnosticReport.rs
              patient/DocumentReference.rs patient/Encounter.rs
              patient/Goal.rs patient/Immunization.rs patient/Location.rs
              patient/MedicationRequest.rs patient/Observation.rs
              patient/Organization.rs patient/Patient.rs
              patient/Practitioner.rs patient/Procedure.rs
              patient/Provenance.rs patient/PractitionerRole.rs
            ).gsub(/\s{2,}/, ' ').strip
          }
        }
      )

      test from: :g10_smart_scopes do
        config(
          inputs: {
            requested_scopes: { name: :standalone_requested_scopes },
            received_scopes: { name: :standalone_received_scopes }
          },
          options: {
            scope_version: :v2
          }
        )

        def required_scopes
          ['openid', 'fhirUser', 'launch/patient', 'offline_access']
        end

        def required_scope_type
          'patient'
        end
      end

      test from: :g10_unauthorized_access,
           config: {
             inputs: {
               patient_id: { name: :standalone_patient_id }
             }
           }

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :standalone_patient_id },
               smart_credentials: { name: :standalone_smart_credentials }
             }
           }
    end

    group from: :smart_openid_connect,
          config: {
            inputs: {
              id_token: { name: :standalone_id_token },
              client_id: { name: :standalone_client_id },
              requested_scopes: { name: :standalone_requested_scopes },
              smart_credentials: { name: :standalone_smart_credentials }
            }
          }

    group from: :g10_token_refresh do
      id :g10_smart_standalone_token_refresh

      config(
        inputs: {
          refresh_token: { name: :standalone_refresh_token },
          client_id: { name: :standalone_client_id },
          client_secret: { name: :standalone_client_secret },
          received_scopes: { name: :standalone_received_scopes }
        },
        outputs: {
          refresh_token: { name: :standalone_refresh_token },
          received_scopes: { name: :standalone_received_scopes },
          access_token: { name: :standalone_access_token },
          token_retrieval_time: { name: :standalone_token_retrieval_time },
          expires_in: { name: :standalone_expires_in },
          smart_credentials: { name: :standalone_smart_credentials }
        }
      )

      test from: :g10_patient_context do
        config(
          inputs: {
            patient_id: { name: :standalone_patient_id },
            smart_credentials: { name: :standalone_smart_credentials }
          },
          options: {
            refresh_test: true
          }
        )
        uses_request :token_refresh
      end
    end

    group from: :g10_unrestricted_resource_type_access,
          config: {
            inputs: {
              received_scopes: { name: :standalone_received_scopes },
              patient_id: { name: :standalone_patient_id },
              smart_credentials: { name: :standalone_smart_credentials }
            }
          }

    test do
      id :g10_standalone_credentials_export
      title 'Set SMART Credentials to Standalone Launch Credentials'

      input :standalone_smart_credentials, type: :oauth_credentials
      input :standalone_patient_id
      output :smart_credentials, :patient_id

      run do
        output smart_credentials: standalone_smart_credentials.to_s,
               patient_id: standalone_patient_id
      end
    end
  end
end
