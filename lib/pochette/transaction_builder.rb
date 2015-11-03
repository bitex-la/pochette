# Builds transactions from a list of source addresses and a list of recipients.
# Uses Pochette.backend to fetch unspent outputs and related transaction data.
# Instantiating will perform all the given queries, you'll be left with a
# TransactionBuilder object that is either valid? or not, and if valid
# you can query the results via to_hash.

class Pochette::TransactionBuilder
  include Contracts::Core

  # Backend can be set globally, or independently for each class and instance.
  class_attribute :backend
  def self.backend
    @backend || Pochette.backend
  end

  cattr_accessor(:dust_size){ 546 }
  cattr_accessor(:output_size){ 35 }
  cattr_accessor(:input_size){ 149 }
  cattr_accessor(:network_minimum_fee){ 10000 }
  cattr_accessor(:default_fee_per_kb){ 12000 }

  Contract ({
    :addresses => C::ArrayOf[String],
    :outputs => C::Maybe[C::ArrayOf[[String, C::Num]]],
    :utxo_blacklist => C::Maybe[C::ArrayOf[[String, Integer]]],
    :change_address => C::Maybe[String],
    :fee_per_kb => C::Maybe[C::Num],
    :spend_all => C::Maybe[C::Bool],
  }) => C::Any
  def initialize(options)
    self.backend = options[:backend] if options[:backend]
    initialize_options(options)
    initialize_fee
    initialize_outputs
    return unless valid?
    select_utxos
    add_change_output
    validate_final_amounts
  end

  Contract C::None => C::Maybe[({
    :input_total => C::Num,
    :output_total => C::Num,
    :fee => C::Num,
    :outputs => C::ArrayOf[[String, C::Num]],
    :inputs => C::ArrayOf[[String, String, Integer, C::Num, String]],
    :utxos_to_blacklist => C::ArrayOf[[String, Integer]]
  })]
  def as_hash
    return nil unless valid?
    { input_total: inputs_amount,
      output_total: outputs_amount,
      fee: inputs_amount - outputs_amount,
      inputs: inputs,
      outputs: outputs,
      utxos_to_blacklist: inputs.collect{|i| [i[1], i[2]] },
    }
  end

  def valid?
    errors.size == 0
  end

  attr_reader :errors

protected

  attr_accessor :options
  attr_accessor :addresses
  attr_accessor :inputs
  attr_accessor :outputs
  attr_writer :errors

  def initialize_options(options)
    self.options = options
    self.errors ||= []
    self.addresses = options[:addresses]
  end

  def initialize_fee
    @minimum_fee = fee_for_bytes(10)
  end

  def add_input_fee(count = 1)
    @minimum_fee += fee_for_bytes(input_size) * count
  end

  def add_output_fee(count = 1)
    @minimum_fee += fee_for_bytes(output_size) * count
  end

  def minimum_fee(stage=0)
    [@minimum_fee + stage, network_minimum_fee].max
  end

  def fee_for_bytes(bytes)
    bytes.to_d / 1000.to_d * (options[:fee_per_kb] || default_fee_per_kb)
  end

  def initialize_outputs
    self.outputs = options[:outputs]
    if (outputs.nil? || outputs.empty?) && !options[:spend_all]
      errors << :try_with_spend_all
      return
    end

    add_output_fee(outputs.size)
    if outputs.any?{|o| o[1] < dust_size }
      errors << :dust_in_outputs
    end
  end

  def select_utxos
    utxo_blacklist = options[:utxo_blacklist] || []
    all_utxos = backend.list_unspent(addresses)
    available_utxos = all_utxos.reject do |utxo|
      utxo_blacklist.include?([utxo[1], utxo[2]])
    end
    
    self.inputs = []
    if options[:spend_all]
      self.inputs = available_utxos
      add_input_fee(inputs.size)
    else
      needed = outputs.collect{|o| o.last }.sum
      collected = 0.to_d
      available_utxos.each do |utxo|
        break if collected >= needed + minimum_fee
        collected += utxo[3]
        self.inputs << utxo
        add_input_fee
      end
    end
  end

  def add_change_output
    change = inputs_amount - outputs_amount -
      minimum_fee(fee_for_bytes(output_size))
    change_address = options[:change_address] || addresses.first
    if change > dust_size
      outputs << [change_address, change]
      add_output_fee
    end
  end

  def inputs_amount
    inputs.collect{|x| x[3] }.sum
  end

  def outputs_amount
    outputs.collect(&:last).sum
  end

  def validate_final_amounts
    if inputs_amount < (outputs_amount + minimum_fee)
      errors << :insufficient_funds
    end
  end
end
