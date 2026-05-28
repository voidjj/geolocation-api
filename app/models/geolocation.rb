# frozen_string_literal: true

class Geolocation < ApplicationRecord
  validates :host, presence: true, uniqueness: true
  validates :ip, presence: true
  validate :host_format_validation

  # RFC 1035 compliant domain regex - internet standard for domain name format
  # RFC 1035 defines domain name structure: labels separated by dots, max 253 chars total
  # Each label: 1-63 chars, start/end with alphanumeric, can contain hyphens
  # Supports: example.com, sub.example.com, api.v2.example.co.uk, test-site.example.com
  DOMAIN_REGEX = /\A(?=.{1,255}$)(?!-)[A-Za-z0-9-]{1,63}(?<!-)(\.(?!-)[A-Za-z0-9-]{1,63}(?<!-))*\.[A-Za-z]{2,}\z/

  private

  def host_format_validation
    return if valid_ip?(host) || valid_domain?(host)

    errors.add(:host, 'must be a valid IP address or domain name')
  end

  def valid_ip?(host)
    IPAddr.new(host)
    true
  rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError, ArgumentError
    false
  end

  def valid_domain?(host)
    host.present? && host.match?(DOMAIN_REGEX)
  end
end
