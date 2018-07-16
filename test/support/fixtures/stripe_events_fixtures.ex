defmodule Flight.StripeEventsFixtures do
  def account_application_deauthorized_fixture() do
    %Stripe.Event{
      account: "acct_00000000000000",
      api_version: "2018-05-21",
      created: 1_326_853_478,
      data: %{
        object: %{
          id: "ca_00000000000000",
          name: "Randon Aviation",
          object: "application"
        }
      },
      id: "evt_00000000000000",
      livemode: false,
      object: "event",
      pending_webhooks: 1,
      request: nil,
      type: "account.application.deauthorized"
    }
  end

  def account_updated_fixture() do
    %Stripe.Event{
      account: "acct_00000000000000",
      api_version: "2018-05-21",
      created: 1_326_853_478,
      data: %{
        object: %Stripe.Account{
          business_logo: "file_1CmT2tAnPjr2CDM4nwR4tPuK",
          business_name: "Randon Aviation",
          business_url: "http://randonaviation.com",
          charges_enabled: true,
          country: "US",
          created: 1_468_531_997,
          debit_negative_balances: true,
          decline_charge_on: %{avs_failure: false, cvc_failure: true},
          default_currency: "usd",
          details_submitted: true,
          display_name: "Randon Aviation",
          email: "test@stripe.com",
          external_accounts: %Stripe.List{
            data: [
              %Stripe.BankAccount{
                account: "acct_18XHSLAnPjr2CDM4",
                account_holder_name: nil,
                account_holder_type: nil,
                bank_name: "MOUNTAIN AMERICA FCU",
                country: "US",
                currency: "usd",
                customer: nil,
                default_for_currency: true,
                fingerprint: "HBnnN7piieroS4YF",
                id: "ba_18XHWaAnPjr2CDM4cQAuAj3E",
                last4: "1655",
                metadata: %{},
                object: "bank_account",
                routing_number: "324079555",
                status: "new"
              }
            ],
            has_more: false,
            object: "list",
            total_count: 1,
            url: "/v1/accounts/acct_18XHSLAnPjr2CDM4/external_accounts"
          },
          id: "acct_00000000000000",
          legal_entity: %{
            additional_owners: [],
            address: %{
              city: "West Jordan",
              country: "US",
              line1: "7220 S 4450 W ",
              line2: nil,
              postal_code: "84088",
              state: "UT"
            },
            business_name: "Cavorite Aviation dba Randon Aviation",
            business_tax_id_provided: true,
            dob: %{day: 31, month: 3, year: 1980},
            first_name: "Randon",
            last_name: "Russell",
            personal_address: %{
              city: nil,
              country: "US",
              line1: nil,
              line2: nil,
              postal_code: nil,
              state: nil
            },
            personal_id_number_provided: true,
            ssn_last_4_provided: true,
            type: "company",
            verification: %{
              details: nil,
              details_code: nil,
              document: nil,
              document_back: nil,
              status: "verified"
            }
          },
          metadata: %{},
          object: "account",
          payout_schedule: %{delay_days: 2, interval: "daily"},
          payout_statement_descriptor: nil,
          payouts_enabled: true,
          product_description: "We are flight school and airplane rentals",
          statement_descriptor: "TEST",
          support_email: "rrussell@randonaviation.com",
          support_phone: "+18015500728",
          timezone: "America/Denver",
          tos_acceptance: %{
            date: 1_472_576_592,
            iovation_blackbox:
              "0400tyDoXSFjKeoNf94lis1ztu5Divh068bwpCrr9RouwVsQ0cKHhjdDVuCrCV90OvpNZ7HmHn7V/sFB2VGALJVF+ded+trm4ecPjZ9ET08wP5DcUJf2lLqlr0nbtw2dg9JBTIBnmyVMxomWiorrwtu9SDEEqrOtKS7LQ3Xefa+YB7KRCB2VV4OJ3Opc6Mk5s04cCjlU0y9oNd/nvDU5IzcjHrKJ+JE3kBBWOH6Zw0dofsT3tXHW0biNyMTNMFyq7LHBSNfOTvsgtn+KY7kcmURuxCfh5nYuDGHOTzEBdNLiXsNS5LoCa7Ohp1QqBoNmFfsAPSX/NxfriTvTynm+nZKW3LzNM6zByOCP3HicHiFzsLzT7W+bd9sPiuO2zOmtp7Xa8aQ5pZ/OJF/jWzshhTzpzK4t/tbAau6SBkAJfMMgCXKKOujBWCG/A/PfBp8j9ZgcIMyfBSWv/vs72mp6+25HIwdhg13I6YIZvZJVRTsOxKGM1eyAwSCEbUL4qyhUXzaj8+g/mDVDCxFKZ8U9CkoIN/IfTON0qqy6iOPW4vbK0P1hO1Q2jmVgfPrA9XDC0LRFSMTVItM+JvgH1g+VsmW7MiaUGABVKw5XPQJ03fMaqxDPd4sgbPQifja5hSZ0AI87MKo5Usr28igxXYd5d+wil/MfxeWxKptW2nex0kLCY1iBURnl+Pl4537jbviEevwogPVs9N2+Q9gnc65/btSo3JWt07KGAe1lwy9qTBJm+Z/wh/o9Lic5vmRZjBPg9ib1sBx6w1tx0mMJbQfJyjgQ+/PvW9NDsI3lEMCy0s3hRLlX3uHnT/mMqyp/6MAGBzULp7/NAcXT+VhLj6ZsyI3AqruvNvEfRkJumOF9AYQzvsoLbh5nOj3u3DXqRCiKCUrsEkMt8z9fxO93iVR/ZwRWb+RG7r+t3dph+Z4baa9a0Da8VDdLGBfK9PH/LgnAtMTg/gz07uVSINAgzJ8FJa/++x9ec0zrP1Wv4XvDcjFK32bI1/apTd0wW60XuqXAU6lPg8V3SNi+5faX+v8aEg8eJDaMgTg0QPJ8t38pWkojSKR48X5U65eABb13drnydLk9RgEqSehE5i2lqiaKSorRtx9C3Sy7/1oJ5KKYY3fgIf+gHlR040VVI5xsYstE+cY+64+6OdLsDjE4kwAZWPynqVpENso5FO8haBdmqUt3qWbmx2vNwg2QelduXJkQUY+REUV/74IQKaLAN411Qcxk8lRn4zUtkMcokW3IdcJQEaR5cHM9RBlGc5a3c3jVldoE",
            ip: "71.35.229.1",
            user_agent: nil
          },
          transfers_enabled: nil,
          type: "standard",
          verification: %{
            disabled_reason: nil,
            due_by: 1_532_040_223,
            fields_needed: ["legal_entity.verification.document"]
          }
        },
        previous_attributes: %{verification: %{due_by: nil, fields_needed: []}}
      },
      id: "evt_00000000000000",
      livemode: false,
      object: "event",
      pending_webhooks: 1,
      request: nil,
      type: "account.updated"
    }
  end
end
