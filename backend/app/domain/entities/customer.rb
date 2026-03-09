# frozen_string_literal: true

require_relative '../errors'

module Domain
  module Entities
    class Customer
      attr_reader :id, :name, :email, :address, :phone
      attr_accessor :errors

      EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

      def initialize(id:, name:, email:, address:, phone:)
        @id      = id
        @name    = name
        @email   = email
        @address = address
        @phone   = phone
        @errors  = []
      end

      def valid?
        @errors = []
        @errors << 'Name is required'    if name.to_s.strip.empty?
        @errors << 'Email is invalid'    unless email.to_s.match?(EMAIL_REGEX)
        @errors << 'Address is required' if address.to_s.strip.empty?
        @errors.empty?
      end

      def to_h
        { id: id, name: name, email: email, address: address, phone: phone }
      end
    end
  end
end
