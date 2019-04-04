drop database if exists spootify;
create database spootify;
use spootify;
drop table if exists user;
drop table if exists buy;
drop table if exists sell;
drop table if exists top_50;

create table user (
	user_id int primary key auto_increment,
    full_name varchar(50) not null,
    user_name varchar(25) unique not null,
    email varchar(255) unique not null,
    password varchar(30) not null,
    created datetime not null,
    portfolio_value int not null,
    purchasing_power int not null,
    leaderboard_rank int not null
    );
 
 create table artist (
	artist_id int primary key,
    artist_name varchar(75) not null,
    genre varchar(30) not null
    );

create table album (
	album_id int primary key,
    album_name varchar(75)
    );
    
create table song(
	spotify_id int primary key,
    title varchar(75) not null,
    artist_id int not null,
    album_id int not null,
    constraint fk_artist_id_song foreign key(artist_id) references artist(artist_id),
    constraint fk_album_id_song foreign key(album_id) references album(album_id)
    );


create table top_50 (
	spotify_id int not null,
    rank int,
    daily_plays int not null,
    stock_value int not null,
    constraint fk_spotify_id_top foreign key(spotify_id) references song(spotify_id)
    );
    
create table history (
	date date not null,
    spotify_id int not null,
    artist_id int not null,
    day_value int not null
    );

    
create table buy (
	buy_id int primary key,
	user_id int not null,
    spotify_id int not null,
    price int not null,
    n_shares int not null,
    purchase_time datetime not null,
    constraint fk_user_id_buy foreign key(user_id) references user(user_id),
    constraint fk_spotify_id_buy foreign key(spotify_id) references top_50(spotify_id)
    );
    
create table sell (
	sell_id int primary key,
	user_id int not null,
    spotify_id int not null,
    price int not null,
    n_shares int not null,
    sale_time datetime not null,
    constraint fk_user_id_sell foreign key(user_id) references user(user_id),
    constraint fk_spotfiy_id_sell foreign key(spotify_id) references top_50(spotify_id)
    );
    
-- buying trigger
Drop Trigger If Exists buy_triggers;

Delimiter //

Create Trigger buy_triggers
	Before Insert On buy
    For Each Row
Begin
	If (New.price * New.n_shares > user.purchasing_power) Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Insufficient Funds';
	End If;
    If (time(New.purchase_time) < '9:30' Or time(New.purchase_time) > '4:30') Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Market Closed';
	End if;
End; //

-- selling trigger
Drop Trigger If Exists sell_triggers;

Delimiter //

Select user_id, sum(n_shares) as shares_bought
From buy
Where user_id = buy.user_id And spotify_id = buy.spotify_id
Group by user_id;

Select user_id, sum(n_shares) as shares_sold
From sell
Where user_id = sell.user_id And spotify_id = sell.spotify_id
Group by user_id;

Create Trigger sell_triggers
	Before Insert On sell
    For Each Row
Begin
	If (New.n_shares > shares_bought - shares_sold) Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Not Enough Shares';
	End If;
    If (time(New.sale_time) < '9:30' Or time(New.sale_time) > '4:30') Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Market Closed';
	End if;
End; //
    




    
