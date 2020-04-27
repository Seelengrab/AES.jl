
function AESCBC(plaintext, iv::Array{UInt8, 1}, key::AbstractAESKey, cache::AbstractAESCache)
	len = length(plaintext)
	pad = 16 - (len % 16)
	ciphertext = similar(Array{UInt8, 1}, pad + len)
	AESCBC!(ciphertext, plaintext, iv, key, cache)
end

function AESCBC!(ciphertext, plaintext, iv::Array{UInt8, 1}, key::AbstractAESKey, cache::AbstractAESCache)
	len = length(plaintext)
	pad = 16 - (len % 16)
	for i in 1:len
		ciphertext[i] = UInt8(plaintext[i])
	end
	for i in 1:pad
		ciphertext[len+i] = pad
	end
	iters = Int((len + pad) / 16)
	for i in 1:iters
		start = 16(i-1)+1
		ending = 16i
		view_res = @view(ciphertext[start:ending])
		if i == 1
			@. view_res = view_res ⊻ iv
		else
			@. view_res = view_res ⊻ @view(ciphertext[start-16:ending-16])
		end
		AESEncryptBlock!(view_res, view_res, key, cache)
	end
	ciphertext
end

function AESCBC_D(ciphertext::Array{UInt8, 1}, iv::Array{UInt8, 1}, key::AbstractAESKey, cache::AbstractAESCache; remove_pad=true)
	len = length(ciphertext)
	iters = Int(len / 16)
	plaintext = similar(Array{UInt8, 1}, len)
	AESCBC_D!(plaintext, ciphertext, iv, key, cache; remove_pad=remove_pad)
end

function AESCBC_D!(plaintext, ciphertext::Array{UInt8, 1}, iv::Array{UInt8, 1}, key::AbstractAESKey, cache::AbstractAESCache; remove_pad=true)
	len = length(ciphertext)
	iters = Int(len / 16)
	for i in 1:iters
		start = 16(i-1)+1
		ending = 16i
		ct_res = @view(ciphertext[start:ending])
		view_res = @view(plaintext[start:ending])
		AESDecryptBlock!(view_res, ct_res, key, cache)
		if i == 1
			@. view_res = view_res ⊻ iv
		else
			@. view_res = view_res ⊻ @view(ciphertext[start-16:ending-16])
		end
	end
	if remove_pad
		pad = plaintext[end]
		@view(plaintext[1:len-pad])
	else
		plaintext
	end
end
