RegisterServerEvent('qb-banking:server:Withdraw')
AddEventHandler('qb-banking:server:Withdraw', function(account, amount, note, fSteamID)
    local src = source
    if not src then return end
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or Player == -1 then
        return
    end

    if not amount or tonumber(amount) <= 0 then
        TriggerClientEvent("qb-banking:client:Notify", source, "error", "Invalid amount!") 
        return
    end

    amount = tonumber(amount)

    if account == "personal" then
        if amount > Player.PlayerData.money["bank"] then
            TriggerClientEvent("qb-banking:client:Notify", source, "error", "Your bank doesn't have this much money!") 
            return
        end
        local withdraw = math.floor(amount)

        Player.Functions.AddMoney('cash', withdraw)
        Player.Functions.RemoveMoney('bank', withdraw)

        RefreshTransactions(source)
        TriggerEvent("qb-banking:server:AddToMoneyLog", source, "personal", -amount, "withdraw", "N/A", (note ~= "" and note or "Withdrew $"..format_int(amount).." cash."))
    end

    if(account == "business") then
        local job = Player.PlayerData.job

        if not SimpleBanking.Config["business_ranks"][string.lower(job.grade.name)] and not SimpleBanking.Config["business_ranks_overrides"][string.lower(job.name)] then
            return
        end

        local low = string.lower(job.name)
        local grade = string.lower(job.grade.name)

        if (SimpleBanking.Config["business_ranks_overrides"][low] and not SimpleBanking.Config["business_ranks_overrides"][low][grade]) then

            return
        end

        local result = exports['ghmattimysql']:executeSync('SELECT * FROM society WHERE name=@name', {['@name'] = job.name})
        local data = result[1]

        if data then
            local sM = tonumber(data.money)
            if sM >= amount then
                TriggerEvent('qb-banking:society:server:WithdrawMoney',src, amount, data.name)

                TriggerEvent("qb-banking:server:AddToMoneyLog", src, "business", -amount, "deposit", job.label, (note ~= "" and note or "Withdrew $"..format_int(amount).." from ".. job.label .."'s account."))
                Player.Functions.AddMoney('cash', amount)
            else
                TriggerClientEvent("qb-banking:client:Notify", src, "error", "Not enough money current balance: €"..sM) 
            end
        end
    end

    if(account == "organization") then
        local gang = Player.PlayerData.gang

        if not SimpleBanking.Config["business_ranks"][string.lower(gang.grade.name)] and not SimpleBanking.Config["business_ranks_overrides"][string.lower(gang.name)] then
            return
        end

        local low = string.lower(gang.name)
        local grade = string.lower(gang.grade.name)

        if (SimpleBanking.Config["business_ranks_overrides"][low] and not SimpleBanking.Config["business_ranks_overrides"][low][grade]) then

            return
        end

        local result = exports['ghmattimysql']:executeSync('SELECT * FROM society WHERE name=@name', {['@name'] = gang.name})
        local data = result[1]

        if data then
            local sM = tonumber(data.money)
            if sM >= amount then
                TriggerEvent('qb-banking:society:server:WithdrawMoney',src, amount, data.name)

                TriggerEvent("qb-banking:server:AddToMoneyLog", src, "organization", -amount, "deposit", gang.label, (note ~= "" and note or "Withdrew $"..format_int(amount).." from ".. gang.label .."'s account."))
                Player.Functions.AddMoney('cash', amount)
            else
                TriggerClientEvent("qb-banking:client:Notify", src, "error", "Not enough money current balance: €"..sM) 
            end
        end
    end
end)