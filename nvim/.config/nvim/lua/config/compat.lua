if vim.fn.has("nvim-0.12") == 1 then
	vim.tbl_flatten = function(tbl)
		local flattened = {}

		local function collect(value)
			if type(value) == "table" and vim.islist(value) then
				for _, item in ipairs(value) do
					collect(item)
				end
			else
				table.insert(flattened, value)
			end
		end

		collect(tbl)
		return flattened
	end
end
