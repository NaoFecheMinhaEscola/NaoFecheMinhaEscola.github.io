require 'csv'
require 'google_places'
require 'yaml'

API_KEYS_PATH = ENV['API_KEYS_PATH']
ESCOLAS_FILE = ENV['ESCOLAS_FILE']

API_KEYS = CSV.read(File.open(API_KEYS_PATH)).flatten
DATA_ESCOLAS_PATH = "_data/escolas.yml"

def write!
  data_escolas_file = File.open(DATA_ESCOLAS_PATH, "w+")
  data_escolas_file.write(YAML.dump(@escolas_hashes))
  data_escolas_file.close
end

escolas_csv = CSV.parse(File.open(ESCOLAS_FILE), col_sep: ';')

@escolas_hashes = []
@key_idx = 0

escolas_csv.each.with_index do |escola, idx|
  begin
    current_key = API_KEYS[@key_idx]
    client = GooglePlaces::Client.new(current_key)
    spots = client.spots_by_query(
      "#{escola[2]} near #{escola[1]}",
      types: ['school']
    )
  rescue GooglePlaces::OverQueryLimitError
    puts "#{@key_idx} PASSOU DO LIMITE"
    @key_idx += 1
    retry if API_KEYS[@key_idx]
  rescue RuntimeError => e
    puts e.message
    puts e.cause
  end


  spot = spots.first if spots
  if spot
    @escolas_hashes << {
      name: escola[2],
      idx: idx,
      address: spot.formatted_address,
      lat: spot.lat,
      lng: spot.lng
    }
  else
    puts " #{idx} - #{escola[2]} não foi encontrada"
  end
  write!
end

