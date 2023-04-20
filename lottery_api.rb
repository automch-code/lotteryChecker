require "httparty"
require "roo"

class LotteryChecker
  include HTTParty
  base_uri "https://www.glo.or.th"

  def initialize()

  end

  def check_lottery_post()
    responses = []

    lottery_data = read_excel_data()
    lottery_params_requests = convert_lottery_data(lottery_data)

    lottery_params_requests.each do |params_request|
      responses << self.class.post(
        "/api/checking/getcheckLotteryResult", 
        body: params_request.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      ).parsed_response
    end

    responses
  end

  private
  
  def read_excel_data()
    xlsx = Roo::Excelx.new("./lottery_2564.xlsx")
    sheet = xlsx.sheet(0)

    hash_bucket = {}

    xlsx.each_row_streaming do |row|
      next if row[1].nil? || row[1].value.to_s == "period_date"
      date = row[1].value.to_s
      hash_bucket[date] = [] if hash_bucket[date] == nil
      hash_bucket[date] << row[0].value
    end

    hash_bucket
  end

  def convert_lottery_data(lottery_data)
    requests = []
    dates = lottery_data.keys
    dates.each do |date|
      requests << {
        "number" => lottery_data[date].map{ { "lottery_num" => _1 } },
        "period_date" => date
      }
    end

    requests
  end
end

lottery_amount = 0
lottery_win = 0

lottery_checker = LotteryChecker.new()
lottery_checker.check_lottery_post().each do |resp|
  resp["response"]["result"].each do |ticket|
    puts "งวดที่: #{ticket["date"]} | เลข: #{ticket["number"]} | ผลลัพธ์: #{ticket["statusType"] == 2 ? 'ไม่ถูกรางวัล' : 'ถูกรางวัล' }"
    lottery_amount += 1
  end
end

puts "สรุป มีหวยทั้งหมด: #{lottery_amount} ใบ | ถูกรางวัล: #{lottery_win} ใบ | ไม่ถูกรางวัล: #{lottery_amount - lottery_win} ใบ"