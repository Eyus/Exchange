// DEVELOPED BY NONAME //


// INCLUDES //
#include <a_samp>
#include <Pawn.CMD>
#include <strlib>
#include <float>
#include <requests>

// DIALOG DEFINES //
#define dialog_transfer_coin_amount (7)
#define dialog_transfer_coin_name   (8)
#define dialog_transfer_adress      (9)
#define dialog_exchange_menu        (10)
#define dialog_exchange 			(11)
#define dialog_create_wallet    	(12)
#define dialog_login_wallet     	(13)
#define dialog_login_wallet_pass    (14)
#define dialog_coins_menu           (15)
#define dialog_coin_select          (16)
#define dialog_coin_orders          (17)
#define dialog_coin_buy             (18)
#define dialog_coin_sell            (19)
#define dialog_order_type           (20)
#define dialog_coin_buy_amount      (21)
#define dialog_coin_sell_amount     (22)
#define dialog_buy_input_price      (23)
#define dialog_sell_input_price     (24)
#define dialog_deposit_money        (25)
#define dialog_withdraw_money       (26)
#define dialog_confirm_password     (27)
#define dialog_new_password         (28)
#define dialog_my_orders            (29)
#define dialog_other_orders         (30)
#define dialog_price_sell_limit     (31) // sj
#define dialog_price_buy_limit      (32)


main()
{
	print("\n----------------------------------");
	print(" WELCOME!!!! n0name SCRIPT BASE");
	print("----------------------------------\n");
}
//  SCRIPT DEFINES //
#define max_wallet_len 				(16)
#define max_wallet_coin_size 		(10)
#define max_wallet_size 			(MAX_PLAYERS*3)
#define BITCOIN_ID  				(0)
#define ETHEREUM_ID 				(1)
#define wallet_all_value        	(-1)
#define MAX_ORDERS 					(1000)
#define order_typ_sell 				(31)
#define order_typ_buy 				(69)
#define valid_block_amount          (343)


// ORDER FUNCTION //
stock GetPercent(value, percent)
{
	return ((value * percent) / 100);
}

stock HowMuchPercent(value, value2)
{
	return ((value2 * 100) / value);
}


// COLOR DEFINES //
#define COLOR_SERVER      	(0xAFAFAFFF)
#define COLOR_RED        	(0xB70000FF)
#define COLOR_YELLOW        (0xFFF700FF)


// MESSAGES DEFINES //
#define ServerMessage(%0,%1) \
	SendClientMessageEx(%0, COLOR_SERVER, "[NO-NAME]:{FFFFFF} "%1)
#define UsingMessage(%0,%1) \
	SendClientMessageEx(%0, COLOR_YELLOW, "USAGE:{FFFFFF} "%1)
#define ErrorMessage(%0,%1) \
	SendClientMessageEx(%0, COLOR_RED, "ERROR:{FFFFFF} "%1)


// PLAYER VALUES ENUM //
enum Player_data
{
	sqlid,
	connected_wallet,
	created_wallet,
	login_screen_timer
}
new pData[MAX_PLAYERS][Player_data];


// WALLET VALUES ENUM //
enum wallet_info
{
	wallet_sql, // WOULD BE INSERT INTO MYSQL AND WALLET SHORT ADRESS BE IT
	bool:wallet_exits,
	wallet_owner,
	wallet_adress[max_wallet_len],
	wallet_password[32],
	Float:wallet_coin[max_wallet_coin_size],
	bool:wallet_order,
	wallet_money
}
new wallet_data[max_wallet_size][wallet_info];

// CRYPTO VALUES ENUM //
enum crypt_info
{
	coin_name[32],
	coin_price,
	Float:buyed_coin,
	Float:selled_coin,
	stack_coin_price,
	Float:stack_sell_coin,
	Float:stack_buy_coin,
	coin_volume,
	coin_short_name[8]
}
new crypt_data[max_wallet_coin_size][crypt_info];

// ORDER VALUES ENUM //
enum order_info
{
	bool:order_create,
	order_price,
	order_type,
	order_coin,
	order_connect_wallet,
	order_owner,
	order_total,
	Float:order_amount
}
new order_data[MAX_ORDERS][order_info];
// SOME FUNCTION //

stock order_color(order_id)
{
	new order_cl[10];
	if(order_data[order_id][order_type] == order_typ_sell)
	{
		format(order_cl, sizeof order_cl, "{FB4906}");
	}
	if(order_data[order_id][order_type] == order_typ_buy)
	{
 	   format(order_cl, sizeof order_cl, "{00C00F}");
	}
	return order_cl;
	// IF ORDER TYPE SELL TEXT COLOR IS RED IF NOT TEXT COLOR IS GREEN
}

// NUMBERS AND CHARS ARRAYS //
new const Chars[] =
{
"A","B","C","D","E","F","G","H","I","J","K","L","N","M","O","P","R", "S", "X", "Y", "Z", "a", "b","c","d","e","f","g","h","i","k","l","n","m","o","p","r","s","x","y","z"
};
new const Number[] = {
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9"
};

// BLOCK TRANSFER FUNCTION //

stock confirm_transfer_block(const target_adress[], source_adress_id, coin_id, Float:coin_amount)
{
	new target, confirm_amount;
	for(new i; i < max_wallet_size; i++)
	{
		if(isequal(target_adress, wallet_data[i][wallet_adress]))
 		{
   	     		target = i;
				confirm_amount++;
 	    	  	break;
  	  	}
	}
	if(wallet_data[source_adress_id][wallet_coin][coin_id] >= coin_amount) confirm_amount++;
	if(confirm_amount >= 2)
	{
		wallet_data[source_adress_id][wallet_coin][coin_id] -= coin_amount;
		wallet_data[target][wallet_coin][coin_id] += coin_amount;
	}
	else
 {
 	   confirm_amount = -1;
 }
	return confirm_amount*valid_block_amount;
}

// PRICE SET AND PRICE CHANGE FUNCTIONS //

stock set_crypto_price_demand(crypto)
{
	if(crypt_data[crypto][selled_coin] == 0 || crypt_data[crypto][buyed_coin] == 0) return 1;
	if(crypt_data[crypto][stack_buy_coin] == crypt_data[crypto][buyed_coin] || crypt_data[crypto][stack_sell_coin] == crypt_data[crypto][selled_coin]) return 1;
	new f, Float:f2, f3;
	f = crypt_data[crypto][coin_price];
	f2 = (crypt_data[crypto][buyed_coin] / crypt_data[crypto][selled_coin]);
	crypt_data[crypto][stack_sell_coin] = crypt_data[crypto][selled_coin], crypt_data[crypto][stack_buy_coin] = crypt_data[crypto][buyed_coin], crypt_data[crypto][stack_coin_price] = crypt_data[crypto][coin_price];
 	f3 = GetPercent(f, floatround(f2, floatround_round));
	if(crypt_data[crypto][buyed_coin] < crypt_data[crypto][selled_coin]) f3 *= -1;
	crypt_data[crypto][stack_coin_price] = crypt_data[crypto][coin_price];
	crypt_data[crypto][coin_price] += f3;
	deliver_orders(-1, crypto);
	return 1;
}

stock set_crypto_price_order(crypto)
{
	new sell_price, buy_price;
	new Float:sell_amount, Float:buy_amount;
	new price, price_sell, price_buy;
	for(new j; j < MAX_ORDERS; j++)
	{
		if(order_data[j][order_coin] == crypto && order_data[j][order_price] > (crypt_data[crypto][coin_price] - GetPercent(crypt_data[crypto][coin_price], 8)) && order_data[j][order_price] < (GetPercent(crypt_data[crypto][coin_price], 8) + crypt_data[crypto][coin_price]))
		{
		    if(order_data[j][order_type] == order_typ_sell)
   		 	{
    			sell_price += order_data[j][order_price];
				sell_amount += order_data[j][order_amount];
				price_sell++;
			}
			else
			{
		 		buy_price += order_data[j][order_price];
				buy_amount += order_data[j][order_amount];
				price_buy++;
			}
		}
	}
	if(buy_amount > sell_amount) price = (buy_price / price_buy);
	if(buy_amount < sell_amount) price = (sell_price / price_sell);
	else return 1;
	crypt_data[crypto][stack_coin_price] = crypt_data[crypto][coin_price];
	crypt_data[crypto][coin_price] = price;
	deliver_orders(-1, crypto);
	return 1;
}

stock set_crypto_price_original(crypto)
{
	new url[32];
	new RequestsClient:coin_request;
	format(url, sizeof url, "%s_usdt/", crypt_data[crypto][coin_short_name]);
	coin_request = RequestsClient("https://www.binance.com/tr/trade/",
	RequestHeaders("title", "close", "content")
	);
	Request(coin_request, url,
		HTTP_METHOD_GET, "OnGetData",
		.headers = RequestHeaders()
	);
	return 1;
}


forward OnGetData(Request:id, E_HTTP_STATUS:status, data[], dataLen);
public OnGetData(Request:id, E_HTTP_STATUS:status, data[], dataLen)
{
	//new data[512];
	//JsonGetString(node, "method", data);
	new coin = -1, iter, price_str[16], price_lenght = -1;
	new coin_namexx[16];
	while(!isequal(data[iter], "|"))
	{
		if(isequal(data[iter], "=")) price_lenght = iter;
	 	iter++;
	}
	for(new j; j < iter-price_lenght; j++)
	{
		format(price_str, sizeof(price_str), "%s%s", price_str, data[price_lenght+1+j]);
 	}
	format(coin_namexx, sizeof coin_namexx, "%s%s%s_%s%s%s", data[iter+1], data[iter+2], data[iter+3], data[iter+4], data[iter+5], data[iter+6]);
	for(new i; i < max_wallet_coin_size; i++)
	{
		if(isequal(coin_namexx, crypt_data[i][coin_short_name]))
  		{
			coin = i;
			break;
		}
	}
	if(coin == -1) return printf("Request failed.");
	ServerMessage(0, "Returned prie: %d", floatround(floatstr(price_str), floatround_round));
	ServerMessage(0, "String Price: %s", price_str);
	ServerMessage(0, "Iter amount: %d | Price Lenght: %d", iter, price_lenght);
	ServerMessage(0, "Iter Char: %s", data[iter]);
	if(coin != -1) ServerMessage(0, "Coin Name: %s", crypt_data[coin][coin_name]);
	ServerMessage(0, "Algorithm Name: %s", coin_namexx);
	if(coin != -1)  ServerMessage(0, "Coin symbol name: %s", crypt_data[coin][coin_short_name]);
	//crypt_data[coin][coin_price] = floatround(floatstr(price_str), floatround_round);
	return 1;
}


stock GetChange(crypto)
{
	new returned[32];
	if(crypt_data[crypto][stack_coin_price] > crypt_data[crypto][coin_price])
	{
	    format(returned, sizeof returned, "{FB4906}- %d.00", crypt_data[crypto][stack_coin_price] - crypt_data[crypto][coin_price]);
	}
	if(crypt_data[crypto][coin_price] > crypt_data[crypto][stack_coin_price])
	{
	    format(returned, sizeof returned, "{00C00F}+ %d.00", crypt_data[crypto][coin_price] - crypt_data[crypto][stack_coin_price]);
	}
	if(crypt_data[crypto][stack_coin_price] < 1 || crypt_data[crypto][stack_coin_price] == crypt_data[crypto][coin_price])
	{
		format(returned, sizeof returned, "{bebebe}0.00");
	}
	return returned;
}

// COIN LIST FUNCTION //
stock list_coin()
{
	new string[1024];
	format(string, sizeof string, "Coin Name\tCoin Price\tPrice Change\tVolume");
	for(new i; i < max_wallet_coin_size; i++)
	{
		if(strlen(crypt_data[i][coin_name]) > 3 && crypt_data[i][coin_price] > 0)
	    {
		   	   format(string, sizeof string, "%s\n%s\t{00C00F}$%d\t%s\t$%d", string, crypt_data[i][coin_name], crypt_data[i][coin_price], GetChange(i), crypt_data[i][coin_volume]);
	    }
	}
	return string;
}
// ORDERS SCRIPTS //

stock deliver_orders(orderID, crypto)
{
	if(orderID == -1)
	{
		for(new i; i < MAX_ORDERS; i++)
		{
		    if(order_data[i][order_coin] == crypto && order_data[i][order_price] == crypt_data[i][coin_price] && order_data[i][order_create] == true)
		    {
				order_data[i][order_create] = false;
				if(order_data[i][order_type] == order_typ_buy)
				{
    				wallet_data[order_data[i][order_connect_wallet]][wallet_coin][crypto] += order_data[i][order_amount];
    			}
 				else
			 	{
     				wallet_data[order_data[i][order_connect_wallet]][wallet_money] += order_data[i][order_total];
				}
		    }
		}
	}
	else
	{
	    order_data[orderID][order_create] = false;
		if(order_data[orderID][order_type] == order_typ_buy)
		{
  			wallet_data[order_data[orderID][order_connect_wallet]][wallet_money] += order_data[orderID][order_total];
  		}
		else
		{
  			wallet_data[order_data[orderID][order_connect_wallet]][wallet_coin][order_data[orderID][order_coin]] += order_data[orderID][order_amount];
		}
	}
	return 1;
}
stock get_line_order(wallet_id, amount)
{
	new amount2 = -1;
	for(new i; i < MAX_ORDERS; i++)
	{
	    if(order_data[i][order_connect_wallet] == wallet_id && order_data[i][order_create] == true)
	    {
	        amount2++;
	    }
	    if(amount2 == amount)
	    {
	        return i;
	    }
	}
	return 1;
}

stock create_order(wallet_id, coin_id, order_typ, Float:coin_amount, price_amount)
{
	new slot;
	for(new i; i < MAX_ORDERS; i++)
	{
	    if(order_data[i][order_create] == false)
	    {
	        slot = i;
	        break;
	    }
	}
	order_data[slot][order_create] = true;
	order_data[slot][order_connect_wallet] = wallet_id;
	order_data[slot][order_coin] = coin_id;
	order_data[slot][order_price] = price_amount;
	order_data[slot][order_amount] = coin_amount;
	if(order_typ == order_typ_buy)
	{
	    order_data[slot][order_type] = order_typ_buy;
	    wallet_data[wallet_id][wallet_money] -= ((floatround(coin_amount, floatround_round) * price_amount));
	    order_data[slot][order_total] = (floatround(coin_amount, floatround_round) * price_amount);
	}
	if(order_typ == order_typ_sell)
	{
	    order_data[slot][order_type] = order_typ_sell;
		wallet_data[wallet_id][wallet_coin][coin_id] -= coin_amount;
	}
	return 1;
}

// WALLETS FUNCTION //
stock create_wallet(playerid, const password[])
{
	new empty_wal;
	for(new i = 1; i < max_wallet_size; i++)
	{
	    if(wallet_data[i][wallet_exits] == false)
	    {
	        empty_wal = i;
	        wallet_data[i][wallet_sql] = i;
	        break;
	    }
	}
	wallet_data[empty_wal][wallet_exits] = true;
	format(wallet_data[empty_wal][wallet_adress], max_wallet_len, "0x");
	create_comp_wallet(playerid, empty_wal);
	pData[playerid][created_wallet]++;
	format(wallet_data[empty_wal][wallet_password], 32, "%s", password);
	printf("%d ID wallet has been created for %d ID's player.", empty_wal, playerid);
	ServerMessage(playerid, "Wallet Adress: %s", wallet_data[empty_wal][wallet_adress]);
	return 1;
}

forward create_comp_wallet(playerid, empty_wal);
public create_comp_wallet(playerid, empty_wal)
{
	new wallet_value = -1;
	do
	{
	    wallet_value = 1;
		for(new k; k < max_wallet_len-2; k++)
		{
			new randomize2 = random(sizeof(Chars));
			new randomize_num = random(sizeof(Number));
			new randomize3 = random(2);
			switch(randomize3)
			{
	  			case 0: format(wallet_data[empty_wal][wallet_adress], max_wallet_len, "%s%d", wallet_data[empty_wal][wallet_adress], Number[randomize_num]);
			    case 1: format(wallet_data[empty_wal][wallet_adress], max_wallet_len, "%s%s", wallet_data[empty_wal][wallet_adress], Chars[randomize2]);
		    }
		}
        for(new i; i < max_wallet_size; i++)
		{
		    if(isequal(wallet_data[empty_wal][wallet_adress], wallet_data[i][wallet_adress]))
		    {
		        wallet_value = -1;
		        break;
		    }
		}
	}
	while(wallet_value != -1);
	return 1;
}


stock clear_wallet(wallet_id)
{
	if(wallet_id > -1)
	{
	    wallet_data[wallet_id][wallet_exits] = false;
	    wallet_data[wallet_id][wallet_adress] = "";
	    wallet_data[wallet_id][wallet_owner] = -1;
	    wallet_data[wallet_id][wallet_password] = "";
	    for(new i; i < max_wallet_coin_size; i++)
		{
			wallet_data[wallet_id][wallet_coin][i] = 0;
	    }
	    printf("%d ID wallet has been clear by online a admin!");
	}
	else if(wallet_id == -1)
	{
	    for(new j; j < max_wallet_size; j++)
	    {
	    	wallet_data[j][wallet_exits] = false;
		    wallet_data[j][wallet_adress] = "";
		    wallet_data[j][wallet_owner] = -1;
		    wallet_data[j][wallet_password] = "";
		    for(new i; i < max_wallet_coin_size; i++)
			{
				wallet_data[j][wallet_coin][i] = 0;
		    }
	    }
	    printf("All wallet has been clear by online a admin!");
	}
	else return 0;
	return 1;
}

// COMMANDS //
CMD:exchange(playerid, params[])
{
	if(pData[playerid][connected_wallet] < 1)
	{
		ShowPlayerDialog(playerid, dialog_exchange, DIALOG_STYLE_LIST, "n0name exchange", "Create Wallet\nLogin Wallet", "Resume", "Exit");
	}
	else
	{
	    if(GetPVarInt(playerid, "showed_login") == 0)
	    {
	        GameTextForPlayer(playerid, "~w~WELCOME THE ~r~ NONAME exchange", 1500, 4);
			pData[playerid][login_screen_timer] = SetTimerEx("login_screen_exchange", 1000, false, "d", playerid);
			SetPVarInt(playerid, "showed_login", 1);
		}
		else return Show_Exchange_Dialog(playerid);
	}
	return 1;
}
stock Show_Exchange_Dialog(playerid)
{
	new info[2048];
	format(info, sizeof info, "Wallet Adress:\n\t%s\nShort Adress\n\t%d", wallet_data[pData[playerid][connected_wallet]][wallet_adress], wallet_data[pData[playerid][connected_wallet]][wallet_sql]);
	format(info, sizeof info, "%s\nBuy/Sell Crypto", info);
	format(info, sizeof info, "%s\nTransfer", info);
	format(info, sizeof info, "%s\nChange Password", info);
	format(info, sizeof info, "%s\nDeposit", info);
	format(info, sizeof info, "%s\nWithdraw", info);
	format(info, sizeof info, "%s\nOrder Book", info);
	format(info, sizeof info, "%s\nTotal Portfloy\n\t", info);
 	format(info, sizeof info, "%sBITCOIN: %f\t\n\t", info, wallet_data[pData[playerid][connected_wallet]][wallet_coin][BITCOIN_ID]);
  	format(info, sizeof info, "%sETHEREUM: %f\n\t", info, wallet_data[pData[playerid][connected_wallet]][wallet_coin][ETHEREUM_ID]);
   	format(info, sizeof info, "%sMoney: $%d\n", info, wallet_data[pData[playerid][connected_wallet]][wallet_money]);
    format(info, sizeof info, "%sExit", info);
	ShowPlayerDialog(playerid, dialog_exchange_menu, DIALOG_STYLE_LIST, "n0name exchange", info, "Select", "Exit");
	return 1;
}


// PUBLICS (TIMER AND IN-GAME PUBLICS) //

forward login_screen_exchange(playerid);
public login_screen_exchange(playerid)
{
	Show_Exchange_Dialog(playerid);
	KillTimer(pData[playerid][login_screen_timer]);
	return 1;
}
public OnFilterScriptInit()
{
	for(new i; i < max_wallet_coin_size; i++)
	{
	    if(i == BITCOIN_ID || i == ETHEREUM_ID)
		{
			crypt_data[ETHEREUM_ID][coin_price] = 2700;
			crypt_data[BITCOIN_ID][coin_price] = 36800;
			format(crypt_data[BITCOIN_ID][coin_name], 32, "Bitcoin");
			format(crypt_data[ETHEREUM_ID][coin_name], 32, "Ethereum");
			format(crypt_data[ETHEREUM_ID][coin_short_name], 8, "eth");
			format(crypt_data[BITCOIN_ID][coin_short_name], 8, "btc");
		}
		else crypt_data[i][coin_price] = -1;
	}
	SetGameModeText("NoNameV1");
	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	return 1;
}
public OnFilterScriptExit()
{
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case dialog_exchange:
	    {
			if(!response) return 1;
			switch(listitem)
			{
			    case 0:
			    {
			        ShowPlayerDialog(playerid, dialog_create_wallet, DIALOG_STYLE_INPUT, "Wallet Create", "Please enter wallet password for create", "Create", "Cancel");
			    }
			    case 1:
			    {
			        ShowPlayerDialog(playerid, dialog_login_wallet, DIALOG_STYLE_INPUT, "Wallet Login", "Please enter a wallet id for login", "Create", "Cancel");
			    }
			}
	    }
	    case dialog_create_wallet:
	    {
	        if(!response) return 1;
	        if(strlen(inputtext) > 32) return ShowPlayerDialog(playerid, dialog_create_wallet, DIALOG_STYLE_INPUT, "Wallet Password", "Wallet password be maximum 32 length", "Login", "Cancel");
	        new pass[32];
	        format(pass, sizeof(pass), "%s", inputtext);
	        create_wallet(playerid, pass);
	    }
	    case dialog_exchange_menu:
	    {
	        if(!response) return 1;
			switch(listitem)
			{
				case 4:
				{
					ShowPlayerDialog(playerid, dialog_coins_menu, DIALOG_STYLE_TABLIST_HEADERS, "n0name exchange", list_coin(), "Select", "Exit");
				}
				case 5:
				{
				    ShowPlayerDialog(playerid, dialog_transfer_adress, DIALOG_STYLE_INPUT, "n0name transfer", "Please enter a wallet adress for transfer", "Transfer", "Exit");
				}
				case 6:
				{
				    ShowPlayerDialog(playerid, dialog_confirm_password, DIALOG_STYLE_INPUT, "n0name password", "Please enter own password for continue", "Confirm", "Exit");
				}
				case 7:
				{
				    ShowPlayerDialog(playerid, dialog_deposit_money, DIALOG_STYLE_INPUT, "n0name deposit", "Please enter want deposit amount: (Minimum $10)", "Deposit", "Exit");
				}
				case 8:
				{
				    ShowPlayerDialog(playerid, dialog_withdraw_money, DIALOG_STYLE_INPUT, "n0name withdraw", "Please enter want withdraw amount: (Minimum $1)", "Withdraw", "Exit");
				}
				case 9:
				{
				    SetPVarInt(playerid, "no_order", 0);
				    new string[3096], header[32];
				    format(header, sizeof(header), "Order Price\tOrder Amount\tOrder Coin");
				    format(string, sizeof(string), "%s\n", header);
				    for(new i; i < MAX_ORDERS; i++)
				    {
				     	if(order_data[i][order_connect_wallet] == pData[playerid][connected_wallet] && order_data[i][order_create] == true)
			 			{
					 		format(string, sizeof(string), "%s%s%d\t%s%f\t%s%s\n", string, order_color(i), order_data[i][order_price], order_color(i), order_data[i][order_amount], order_color(i), crypt_data[order_data[i][order_coin]][coin_name]);
						}
				    }
				    if(strlen(string) <= strlen(header)+5)
				    {
				        format(string, sizeof(string), "You havent a order.");
						SetPVarInt(playerid, "no_order", 1);
				    }
        			ShowPlayerDialog(playerid, dialog_my_orders, DIALOG_STYLE_TABLIST_HEADERS, "My Orders", string, "Order Cancel", "Exit");
				}
				case 14:
				{
				    pData[playerid][connected_wallet] = -1;
				    ServerMessage(playerid, "Exit succesful.");
				}
			}
	    }
	    case dialog_my_orders:
	    {
	        if(!response) return Show_Exchange_Dialog(playerid);
			if(GetPVarInt(playerid, "no_order") != 1)
			{
			    deliver_orders(get_line_order(pData[playerid][connected_wallet], listitem), 1);
				ServerMessage(playerid, "Order has been canceled.");
				Show_Exchange_Dialog(playerid);
			}
			else Show_Exchange_Dialog(playerid);
	    }
	    case dialog_confirm_password:
	    {
	        if(!response) return Show_Exchange_Dialog(playerid);
	        if(isequal(inputtext, wallet_data[pData[playerid][connected_wallet]][wallet_password]))
	        {
	            ShowPlayerDialog(playerid, dialog_new_password, DIALOG_STYLE_INPUT, "n0name password", "Please enter new password", "Change", "Exit");
	        }
	        else return ErrorMessage(playerid, "Wrong password.");
	    }
	    case dialog_new_password:
	    {
	        if(!response) return Show_Exchange_Dialog(playerid);
	        if(strlen(inputtext) > 32) return ShowPlayerDialog(playerid, dialog_new_password, DIALOG_STYLE_INPUT, "n0name password", "New password must be maximum 32 length", "Change", "Exit");
	        format(wallet_data[pData[playerid][connected_wallet]][wallet_password], 32, "%s", inputtext);
	        ServerMessage(playerid, "Password has changed.");
	    }
	    case dialog_deposit_money:
	    {
	        if(!response) return Show_Exchange_Dialog(playerid);
	        if(GetPlayerMoney(playerid) < strval(inputtext)) return ErrorMessage(playerid, "You havent this money!");
			if(strval(inputtext) < 10) return ErrorMessage(playerid, "Too low money!");
			GivePlayerMoney(playerid, -strval(inputtext));
			wallet_data[pData[playerid][connected_wallet]][wallet_money] += strval(inputtext);
			ServerMessage(playerid, "You are succesfully deposit $%d.", strval(inputtext));
	    }
	    case dialog_withdraw_money:
	    {
     		if(!response) return Show_Exchange_Dialog(playerid);
	        if(wallet_data[pData[playerid][connected_wallet]][wallet_money] < strval(inputtext)) return ErrorMessage(playerid, "Your wallet hasnt this money!");
			if(strval(inputtext) < 1) return ErrorMessage(playerid, "Too low money!");
			GivePlayerMoney(playerid, strval(inputtext));
			wallet_data[pData[playerid][connected_wallet]][wallet_money] -= strval(inputtext);
			ServerMessage(playerid, "You are succesfully withdraw $%d.", strval(inputtext));
	    }
	    case dialog_coins_menu:
	    {
	        if(!response) return Show_Exchange_Dialog(playerid);
	        SetPVarInt(playerid, "selected_coin", listitem);
	        ShowPlayerDialog(playerid, dialog_coin_select, DIALOG_STYLE_LIST, "n0name exchange", "Buy\nSell\nOrder Book", "Select", "Exit");
	    }
	    case dialog_coin_select:
	    {
	        if(!response) return Show_Exchange_Dialog(playerid);
			switch(listitem)
			{
				case 0:
				{
					ShowPlayerDialog(playerid, dialog_coin_buy, DIALOG_STYLE_LIST, "Select Order Type", "Market Order\nLimit Order", "Select", "Exit");
				}
				case 1:
				{
				    ShowPlayerDialog(playerid, dialog_coin_sell, DIALOG_STYLE_LIST, "Select Order Type", "Market Order\nLimit Order", "Select", "Exit");
				}
				case 2:
				{
    				new string[2048], header[32];
				    format(header, sizeof(header), "Order Price\tOrder Amount\tOrder Coin");
				    format(string, sizeof(string), "%s\n", header);
				    for(new i; i < MAX_ORDERS; i++)
				    {
				     	if(order_data[i][order_create] == true && order_data[i][order_coin] == GetPVarInt(playerid, "selected_coin"))
			 			{
					 		format(string, sizeof(string), "%s%s%d\t%s%f\t%s%s\n", string, order_color(i), order_data[i][order_price], order_color(i), order_data[i][order_amount], order_color(i), crypt_data[order_data[i][order_coin]][coin_name]);
						}
				    }
				    if(strlen(string) <= strlen(header)+5)
				    {
				        format(string, sizeof(string), "No order.");
				    }
        			ShowPlayerDialog(playerid, dialog_other_orders, DIALOG_STYLE_TABLIST_HEADERS, "Order Books", string, "Order Cancel", "Exit");
				}
			}
	    }
	    case dialog_other_orders:
		{
		    Show_Exchange_Dialog(playerid);
	    }
	    case dialog_coin_buy:
	    {
	        if(!response) return Show_Exchange_Dialog(playerid);
	        SetPVarInt(playerid, "selected_order_type", listitem);
	        new string[256];
	        format(string, sizeof string, "Total Money: $%d | 1 %s: $%d", wallet_data[pData[playerid][connected_wallet]][wallet_money], crypt_data[GetPVarInt(playerid, "selected_coin")][coin_name], crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price]);
    		ShowPlayerDialog(playerid, dialog_coin_buy_amount, DIALOG_STYLE_INPUT, "n0name exchange", string, "Buy", "Exit");
	    }
	    case dialog_price_buy_limit:
	    {
			if(strval(inputtext) < (crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price] - GetPercent(crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price], 8)))
	        {
	            ShowPlayerDialog(playerid, dialog_price_buy_limit, DIALOG_STYLE_INPUT, "n0name Order", "Too low limit.", "Order", "Exit");
	        }
	        if(wallet_data[pData[playerid][connected_wallet]][wallet_money] < ((strval(inputtext) * floatround(GetPVarFloat(playerid, "order_coin_amount")))))
	        {
	            ShowPlayerDialog(playerid, dialog_price_buy_limit, DIALOG_STYLE_INPUT, "n0name Order", "You dont have this much money.", "Order", "Exit");
	        }
	        else
	        {
	            create_order(pData[playerid][connected_wallet], GetPVarInt(playerid, "selected_coin"), order_typ_buy, GetPVarFloat(playerid, "order_coin_amount"), strval(inputtext));
	            ServerMessage(playerid, "Order succesfully created.");
	        }
	        return 1;
	    }
	    case dialog_price_sell_limit:
	    {
			if(strval(inputtext) > (crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price] + GetPercent(crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price], 8)))
	        {
	            ShowPlayerDialog(playerid, dialog_price_buy_limit, DIALOG_STYLE_INPUT, "n0name Order", "Too high limit.", "Order", "Exit");
	        }
	        else
	        {
	            create_order(pData[playerid][connected_wallet], GetPVarInt(playerid, "selected_coin"), order_typ_sell, GetPVarFloat(playerid, "order_coin_amount"), strval(inputtext));
	            ServerMessage(playerid, "Order succesfully created.");
	        }
	        return 1;
	    }
	    case dialog_coin_buy_amount:
	    {
	        if(!response) return Show_Exchange_Dialog(playerid);
			if(GetPVarInt(playerid, "selected_order_type") == 0)
			{
			    new Float:coin_amount = floatstr(inputtext);
			    if(wallet_data[pData[playerid][connected_wallet]][wallet_money] >= floatround((coin_amount * float(crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price])), floatround_round))
			    {
			        printf("%d degeri", GetPVarInt(playerid, "selected_coin"));
      				wallet_data[pData[playerid][connected_wallet]][wallet_coin][GetPVarInt(playerid, "selected_coin")] += coin_amount;
					wallet_data[pData[playerid][connected_wallet]][wallet_money] -= floatround((coin_amount * float(crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price])), floatround_round);
					ServerMessage(playerid, "Order succesful.");
					crypt_data[GetPVarInt(playerid, "selected_coin")][buyed_coin] += coin_amount;
					crypt_data[GetPVarInt(playerid, "selected_coin")][coin_volume] += floatround((coin_amount * float(crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price])), floatround_round);
			    }
			    else return ErrorMessage(playerid, "Order failed. Your wallet hasnt this much money.");
			}
			else
			{
			    new string[256];
			    format(string, sizeof string, "Please write limit. Minimum: $%d", (crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price] - GetPercent(crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price], 8)));
			    SetPVarFloat(playerid, "order_coin_amount", floatstr(inputtext));
			    ShowPlayerDialog(playerid, dialog_price_buy_limit, DIALOG_STYLE_INPUT, "n0name Order", string, "Order", "Exit");
			}
	    }
	    case dialog_coin_sell:
	    {
	        if(!response) return Show_Exchange_Dialog(playerid);
	        SetPVarInt(playerid, "selected_order_type", listitem);
	        new string[256];
	        format(string, sizeof string, "Total Coin: %f | 1 %s: $%d", wallet_data[pData[playerid][connected_wallet]][wallet_coin][GetPVarInt(playerid, "selected_coin")], crypt_data[GetPVarInt(playerid, "selected_coin")][coin_name], crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price]);
         	ShowPlayerDialog(playerid, dialog_coin_sell_amount, DIALOG_STYLE_INPUT, "n0name exchange", string, "Buy", "Exit");
	    }
	    case dialog_coin_sell_amount:
	    {
	        if(!response) return Show_Exchange_Dialog(playerid);
			if(GetPVarInt(playerid, "selected_order_type") == 0)
			{
			    new Float:coin_amount = floatstr(inputtext);
			    if(wallet_data[pData[playerid][connected_wallet]][wallet_coin][GetPVarInt(playerid, "selected_coin")] >= coin_amount)
			    {
      				wallet_data[pData[playerid][connected_wallet]][wallet_coin][GetPVarInt(playerid, "selected_coin")] -= coin_amount;
					wallet_data[pData[playerid][connected_wallet]][wallet_money] += floatround((coin_amount * float(crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price])), floatround_round);
					ServerMessage(playerid, "Order succesful.");
					crypt_data[GetPVarInt(playerid, "selected_coin")][selled_coin] += coin_amount;
					crypt_data[GetPVarInt(playerid, "selected_coin")][coin_volume] += floatround((coin_amount * float(crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price])), floatround_round);
			    }
			    else return ErrorMessage(playerid, "Order failed. Your wallet hasnt this much coin.");
			}
			else
			{
   				new string[256];
			    format(string, sizeof string, "Please write limit. Maximum: $%d", (crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price] + GetPercent(crypt_data[GetPVarInt(playerid, "selected_coin")][coin_price], 8)));
			    SetPVarFloat(playerid, "order_coin_amount", floatstr(inputtext));
			    ShowPlayerDialog(playerid, dialog_price_sell_limit, DIALOG_STYLE_INPUT, "n0name Order", string, "Order", "Exit");
			}
	    }
	    case dialog_transfer_adress:
	    {
     		if(!response) return Show_Exchange_Dialog(playerid);
			new walletid = -31;
			for(new i; i < max_wallet_size; i++)
			{
			    if(isequal(inputtext, wallet_data[i][wallet_adress]))
			    {
			        walletid = i;
			        break;
				}
			}
			if(walletid == -31)
			{
			    ErrorMessage(playerid, "Transfer cancelled. Wrong adress.");
			}
			else
			{
			    ShowPlayerDialog(playerid, dialog_transfer_coin_name, DIALOG_STYLE_INPUT, "n0name transfer", "Please a coin name for transfer", "Resume", "Cancel");
				SetPVarInt(playerid, "transfered_id", walletid);
			}
	    }
	    case dialog_transfer_coin_name:
	    {
     		if(!response) return 1;
	        new coin_id = -1;
	        for(new i; i < max_wallet_coin_size; i++)
	        {
	            if(isequal(crypt_data[i][coin_name], inputtext))
				{
				    coin_id = i;
				    break;
				}
	        }
	        if(coin_id == -1)
	        {
	            ShowPlayerDialog(playerid, dialog_transfer_coin_name, DIALOG_STYLE_INPUT, "n0name transfer", "Wrong coin name. Please write again:", "Resume", "Cancel");
	        }
	        else
	        {
                ShowPlayerDialog(playerid, dialog_transfer_coin_amount, DIALOG_STYLE_INPUT, "n0name transfer", "Please write want coin amount:", "Resume", "Cancel");
				SetPVarInt(playerid, "transfer_coin", coin_id);
	        }
	    }
	    case dialog_transfer_coin_amount:
	    {
	        if(!response) return 1;
	        if(floatstr(inputtext) < 0 || floatstr(inputtext) == 0.0)
	        {
                 ShowPlayerDialog(playerid, dialog_transfer_coin_amount, DIALOG_STYLE_INPUT, "n0name transfer", "Wrong amount. Please write again:", "Resume", "Cancel");
	        }
	        if(wallet_data[pData[playerid][connected_wallet]][wallet_coin][GetPVarInt(playerid, "transfer_coin")] < floatstr(inputtext))
	        {
	            ShowPlayerDialog(playerid, dialog_transfer_coin_amount, DIALOG_STYLE_INPUT, "n0name transfer", "Wrong amount. Please write again:", "Resume", "Cancel");
	        }
	        else
	        {
				new block_amount = confirm_transfer_block(wallet_data[GetPVarInt(playerid, "transfered_id")][wallet_adress], pData[playerid][connected_wallet], GetPVarInt(playerid, "transfer_coin"), floatstr(inputtext));
				if(block_amount < 0) return ErrorMessage(playerid, "Our system alert a error. Please contact us.");
				else
				{
					ServerMessage(playerid, "Transfer has been succesfully. Transfer validated by %d block.", block_amount);
				}
	        }
	    }
	    case dialog_login_wallet:
	    {
	        if(!response) return 1;
	        if(isequal(inputtext, "")) return 1;
	        if(strlen(inputtext) >= max_wallet_len-2)
			{
			    new walletid = -33;
				for(new i; i < max_wallet_size; i++)
				{
				    if(isequal(inputtext, wallet_data[i][wallet_adress]))
				    {
						walletid = i;
						break;
				    }
				}
				if(walletid == -33)
				{
                    ShowPlayerDialog(playerid, dialog_login_wallet, DIALOG_STYLE_INPUT, "Wallet Login", "Wrong wallet id or adress", "Login", "Cancel");
				}
				else
				{
					ShowPlayerDialog(playerid, dialog_login_wallet_pass, DIALOG_STYLE_PASSWORD, "Wallet Login", "Please enter writed wallet password", "Enter", "Exit");
					SetPVarInt(playerid, "writedWallet", walletid);
				}
			}
			else
			{
		 		new walletid = -33;
				for(new i; i < max_wallet_size; i++)
				{
				    if(strval(inputtext) == wallet_data[i][wallet_sql])
				    {
						walletid = i;
						break;
				    }
				}
				if(walletid == -33)
				{
                    ShowPlayerDialog(playerid, dialog_login_wallet, DIALOG_STYLE_INPUT, "Wallet Login", "Wrong wallet id or adress", "Login", "Cancel");
				}
				else
				{
					ShowPlayerDialog(playerid, dialog_login_wallet_pass, DIALOG_STYLE_PASSWORD, "Wallet Login", "Please enter writed wallet password", "Enter", "Exit");
					SetPVarInt(playerid, "writedWallet", walletid);
				}
			}
	    }
	    case dialog_login_wallet_pass:
	    {
	        if(!response) return DeletePVar(playerid, "writedWallet");
	        if(isequal(wallet_data[GetPVarInt(playerid, "writedWallet")][wallet_password], inputtext))
	        {
	            pData[playerid][connected_wallet] = GetPVarInt(playerid, "writedWallet");
	            ServerMessage(playerid, "You are succesfully login '%s' adress wallet.", wallet_data[GetPVarInt(playerid, "writedWallet")][wallet_adress], pData[playerid][connected_wallet]);
	        }
	    }
	}
	return 1;
}

// SPECIAL MESSAGE FUNCTION //

stock SendClientMessageEx(playerid, color, const text[], {Float, _}:...)
{
	static args, str[144];
	if((args = numargs()) == 3)
	{
	    SendClientMessage(playerid, color, text);
	}
	else
	{
		while (--args >= 3)
		{
			#emit LCTRL 5
			#emit LOAD.alt args
			#emit SHL.C.alt 2
			#emit ADD.C 12
			#emit ADD
			#emit LOAD.I
			#emit PUSH.pri
		}
		#emit PUSH.S text
		#emit PUSH.C 144
		#emit PUSH.C str
		#emit PUSH.S 8
		#emit SYSREQ.C format
		#emit LCTRL 5
		#emit SCTRL 4

		SendClientMessage(playerid, color, str);

		#emit RETN
	}
	return true;
}
