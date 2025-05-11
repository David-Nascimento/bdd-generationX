module CLI
  def self.selecionar_arquivos_txt(diretorio)
    arquivos = Dir.glob("#{diretorio}/*.txt")

    if arquivos.empty?
      puts "❌ Nenhum arquivo .txt encontrado no diretório '#{diretorio}'"
      exit
    end
  
    arquivos

    puts "📂 Arquivos disponíveis em '#{diretorio}':"
    arquivos.each_with_index do |arquivo, i|
      puts "  #{i + 1}. #{File.basename(arquivo)}"
    end

    print "\nDigite os números dos arquivos que deseja processar (ex: 1,2,3 ou 'todos'): "
    entrada = gets.chomp

    selecionados = if entrada.downcase == 'todos'
                     arquivos
                   else
                     indices = entrada.split(',').map { |n| n.strip.to_i - 1 }
                     indices.map { |i| arquivos[i] }.compact
                   end

    if selecionados.empty?
      puts "❌ Nenhum arquivo válido selecionado."
      exit
    end

    selecionados
  end
end
