require_relative 'SimcConfig'

module ProfileHelper
  # Fetch an override profile from the given prefix with the talents matching the file talent string
  def self.GetTalentOverrides(prefix, talents)
    Dir.glob("#{SimcConfig['ProfilesFolder']}/#{prefix}_*\.simc").each do |file|
      catch (:unmatchingTalents) do
        if data = file.match(/#{SimcConfig['ProfilesFolder']}\/#{prefix}_([0-3xX]{7})\.simc/)
          talentstring = data[1].downcase
          (0..6).to_a.each do |tier|
            throw :unmatchingTalents if talentstring[tier] != 'x' && talentstring[tier] != talents[tier]
          end
          return GetAsOverrideLines(file)
        end
      end
    end
    return []
  end

  # Fetch an override profile from the given prefix with the file's special item matching
  # Convert spaces to dashes
  def self.GetSpecialOverrides(prefix, special)
    special = special.gsub(' ', '-')
    Dir.glob("#{SimcConfig['ProfilesFolder']}/#{prefix}_*\.simc").each do |file|
      if data = file.match(/#{SimcConfig['ProfilesFolder']}\/#{prefix}_([-a-zA-Z0-9]*)\.simc/)
        return GetAsOverrideLines(file) if data[1] == special
      end
    end
    return []
  end

  def self.GetAsOverrideLines(file)
    overrideLines = []
    File.open(file) do |ofile|
      while line = ofile.gets
        line.chomp!
        overrideLines.push(line) unless line.empty?
      end
    end
    return overrideLines
  end

  # Fetch the sim value for given key string from a profile (works recursively with $(simc_profiles_path))
  def self.GetValueFromTemplate(simcKey, file)
    value = nil
    File.open(file, 'r') do |pfile|
      while line = pfile.gets
        if line.start_with?("#{simcKey}=")
          value = line.chomp.split('=', 2)[1]
        elsif line.chomp.end_with?('.simc')
          subfile = line.chomp.gsub('input=', '').gsub('$(simc_profiles_path)', "#{SimcConfig['SimcPath']}/profiles")
          subvalue = GetValueFromTemplate(simcKey, subfile)
          value = subvalue if subvalue
        end
      end
    end
    return value
  end
end
