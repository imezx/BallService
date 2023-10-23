--!strict
return function(condition: any, message: string, silent: boolean): boolean?
	if (condition) and not silent then warn(message) end return (condition)
end