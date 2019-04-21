drop database if exists spootify;
create database spootify;
use spootify;



        
create table genre (
	genre_id varchar(10) primary key,
    genre_name varchar(30)
    );
 

    
 create table artist (
	artist_id varchar(10) primary key,
    artist_name varchar(75) not null,
    genre_id varchar(10) not null,
    constraint fk_genre_id_artist foreign key(genre_id) references genre(genre_id)
    );

    
    
create table album (
	album_id varchar(10) primary key,
    album_name varchar(75)
    );
    

    
create table song(
	spotify_id varchar(10) primary key,
    title varchar(75) not null,
    artist_id varchar(10) not null,
    album_id varchar(10) not null,
    song_value int not null,
    constraint fk_artist_id_song foreign key(artist_id) references artist(artist_id),
    constraint fk_album_id_song foreign key(album_id) references album(album_id)
    );

    
create table song_history (
	date date not null,
    spotify_id varchar(10) not null,
    day_value int not null,
    constraint fk_spotify_id_song_history foreign key(spotify_id) references song(spotify_id)
    );
    
    
    

create table user (
	user_id int primary key auto_increment,
    full_name varchar(50) not null,
    user_name varchar(25) unique not null,
    email varchar(255) unique not null,
    password varchar(30) not null,
    created datetime not null,
    purchasing_power int not null
    );


create table user_history (
	date date not null,
    user_id int not null,
    portfolio_value int not null,
    constraint fk_spotify_id_user_history foreign key(user_id) references user(user_id)
    );
    
    
    
    
create table buy (
	buy_id int primary key auto_increment,
	user_id int not null,
    spotify_id varchar(10) not null,
    price int not null,
    n_shares int not null,
    purchase_time datetime not null,
    constraint fk_user_id_buy foreign key(user_id) references user(user_id),
    constraint fk_spotify_id_buy foreign key(spotify_id) references song(spotify_id)
    );
    
    
    
create table sell (
	sell_id int primary key auto_increment,
	user_id int not null,
    spotify_id varchar(10) not null,
    price int not null,
    n_shares int not null,
    sale_time datetime not null,
    constraint fk_user_id_sell foreign key(user_id) references user(user_id),
    constraint fk_spotfiy_id_sell foreign key(spotify_id) references song(spotify_id)
    );
    


            
-- buying trigger
-- prevents users from buying more shares than they can afford
-- prevents users from purchasing outside of of market ours
-- updates user's purchasing power based off purchase
Drop Trigger If Exists buy_triggers;

Delimiter //
Create Trigger buy_triggers
	Before Insert On buy
    For Each Row
Begin
	If ((New.price * New.n_shares) > (Select purchasing_power as u_power
										From user
										Where New.user_id = user.user_id))
		Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Insufficient Funds';
	End If;
    If (time(New.purchase_time) < '09:30' Or time(New.purchase_time) > '16:30') Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Market Closed';
	Else
		Update user
        Set purchasing_power = purchasing_power - (New.n_shares * New.price)
        Where user.user_id = New.user_id;
	End If;
End //


Delimiter //

-- function that calculates shares of given stock bought by a given user
CREATE FUNCTION shares_bought (u_id INT, s_id varchar(10))
RETURNS INT

BEGIN
DECLARE bought INT;

Select sum(n_shares) into bought
From buy
Where u_id = user_id And s_id = spotify_id
Group by user_id, spotify_id;

RETURN bought;
END //

Delimiter //

-- function that calculates shares of given stock sold by a given user
CREATE FUNCTION shares_sold (u_id INT, s_id varchar(10))
RETURNS INT

BEGIN
DECLARE sold INT;

Select sum(n_shares) into sold
From sell
Where u_id = user_id And s_id = spotify_id
Group by user_id, spotify_id;

RETURN sold;
END //


Drop Trigger If Exists sell_triggers;

Delimiter //


-- trigger based of sales being made
-- prevents users from selling more shares than they own
-- prevents users from selling outside of of market ours
-- updates user's purchasing power based off sale
Create Trigger sell_triggers
	Before Insert On sell
    For Each Row
Begin
	If (New.n_shares > shares_bought(New.user_id, New.spotify_id) - shares_sold(New.user_id, New.spotify_id)) Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Not Enough Shares';
	End If;
    If (time(New.sale_time) < '09:30' Or time(New.sale_time) > '16:30') Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Market Closed';
	Else
		Update user
        Set purchasing_power = purchasing_power + (New.n_shares * New.price)
        Where user.user_id = New.user_id;
	End If;
End //
 
 
 -- updates song history every day
create event update_song_history
	on schedule every 1 day
	starts '2019-01-01 00:05:00' 
do
	insert into song_history
    select curdate(), spotify_id, song_value
    from song;


-- updates user history every day (makes a copy of user's history at the end of the day)
create event update_user_history
	on schedule every 1 day
	starts '2019-01-01 00:09:00'
do
	insert into user_history
    select curdate(), user_id, portfolio_value
    from 
    (Select user_id, (sum(total_value) + purchasing_power) as portfolio_value
		From
		(Select user_id, spotify_id, shares_owned * song_value as total_value
		From
			(Select user_id, spotify_id, user_bought - coalesce(user_sold,0) as shares_owned
			From 
				(Select user_id, spotify_id, sum(n_shares) as user_bought
				From buy
				Group by user_id, spotify_id) as total_bought
			Left Join 
				(Select user_id, spotify_id, sum(n_shares) as user_sold
				From sell
				Group by user_id, spotify_id) as total_sold
				Using (user_id, spotify_id)) as user_total
		Join song Using (spotify_id)) as user_share_value
	Join user Using (user_id)
	Group by user_id) as daily_portfolio
Where user.user_id = daily_portfolio.user_id;

 



