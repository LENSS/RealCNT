configuration IdentityC{
	provides interface Identity;
}
implementation{
	components IdentityP;
	
	Identity = IdentityP;
}