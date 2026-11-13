Config = {}

-- Grupos ESX autorizados a abrir o painel.
Config.AllowedGroups = {
    admin = true,
    superadmin = true
}

-- Comando para abrir o painel.
Config.Command = 'novamenu'

-- Distância máxima para interagir com uma porta.
Config.DoorDistance = 2.0

-- Intervalo de verificação das portas (ms).
Config.DoorCheckInterval = 500

-- Se true, qualquer jogador pode usar /novamenu e o servidor valida o grupo.
Config.EnableCommand = true

-- Jobs existentes são carregados da tabela jobs do ESX.
-- Novos jobs são inseridos automaticamente em jobs e job_grades.
